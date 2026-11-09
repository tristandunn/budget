# frozen_string_literal: true

class BudgetSnapshot
  delegate :current_month?,
           :date,
           :first_month?,
           :future_month?,
           :last_month?,
           :next_date,
           :previous_date,
           :snapshot_range,
           to: :snapshot_date

  delegate :available_amounts,
           :monthly_target_categories,
           :snapshots,
           to:      :month,
           private: true

  # Initialize the budget snapshot.
  #
  # The displayed month falls back to the current month when no date is
  # supplied.
  #
  # @param budget [Budget] The budget to summarize.
  # @param date [Date, nil] The first day of the month to display.
  # @param month [BudgetSnapshotMonth, nil] The values already loaded for the month, which avoids queries when supplied.
  # @param snapshot_range [Range<Date>, nil] The known range of navigable months, which avoids a query when supplied.
  def initialize(budget, date: nil, month: nil, snapshot_range: nil)
    @budget         = budget
    @month          = month
    @requested_date = date
    @snapshot_range = snapshot_range
  end

  # Return the available amount for a category, summed across every snapshot
  # up to and including the displayed month. For a top-level category, sum
  # the available amounts of its subcategories.
  #
  # @param category [Category] The category or category group.
  # @return [Integer] The available amount in cents.
  def available_for(category)
    amount_for(category, available_amounts)
  end

  # Return whether the budget's monthly targets are fully funded for the
  # displayed month.
  #
  # @return [Boolean] Whether the monthly targets are fully funded.
  def funded?
    funded_percentage == 100
  end

  # Return the percentage funded for the displayed month across the budget's
  # monthly targets, clamped between 0 and 100, or zero when there are no
  # monthly targets. A snoozed target counts as fully funded.
  #
  # @return [Integer] The funded percentage, between 0 and 100.
  def funded_percentage
    total_target = monthly_target_categories.sum(&:target_amount)

    if total_target.positive?
      funded = monthly_target_categories.sum do |category|
        if snoozed?(category)
          category.target_amount
        else
          [target_progress_for(category).funded_amount, category.target_amount].min
        end
      end

      (funded * 100 / total_target).clamp(0, 100)
    else
      0
    end
  end

  # Return snapshots for the future months that have assignments, capped at
  # `BudgetSnapshotMonth::FUTURE_MONTH_LIMIT` and ordered from the nearest
  # month. Every future month is handed the values loaded alongside this month,
  # so the whole set costs a handful of queries.
  #
  # @return [Array<BudgetSnapshot>] The future-month snapshots, nearest first.
  def future_months
    @future_months ||= month.future_months.map do |future_month|
      self.class.new(
        budget,
        date:           future_month.date,
        month:          future_month,
        snapshot_range: snapshot_range
      )
    end
  end

  # Return the available amount carried in from prior months for the category,
  # summed across every snapshot before the displayed month. For a top-level
  # category, sum the rolled-over amounts of its subcategories.
  #
  # @param category [Category] The category or category group.
  # @return [Integer] The rolled-over amount in cents.
  def rollover_for(category)
    available_for(category) - amount_for(category, snapshots.transform_values(&:amount_remaining))
  end

  # Return the category snapshot for the given category ID, initializing a new
  # one if none exists.
  #
  # @param category_id [Integer] The ID of the category to look up.
  # @return [CategorySnapshot] The category snapshot for the given category ID.
  def snapshot_for(category_id)
    snapshots[category_id] ||= CategorySnapshot.new
  end

  # Return whether the category currently has a monthly target and the
  # displayed-month snapshot has been snoozed.
  #
  # @param category [Category] The category to evaluate.
  # @return [Boolean] Whether the category is snoozed for the displayed month.
  def snoozed?(category)
    category.monthly_target? && snapshot_for(category.id).snoozed?
  end

  # Return the target progress for the given category.
  #
  # @param category [Category] The category to evaluate.
  # @return [TargetProgress] The target progress for the category.
  def target_progress_for(category)
    TargetProgress.new(
      category:     category,
      future_month: future_month?,
      rollover:     rollover_for(category),
      snapshot:     snapshot_for(category.id)
    )
  end

  # Return the total assigned for the displayed month across every
  # non-inflow category.
  #
  # @return [Integer] The assigned amount in cents.
  def total_assigned
    budget.assignable_categories.sum do |category|
      snapshot_for(category.id).amount_assigned
    end
  end

  # Return the cumulative available amount across every non-inflow category,
  # summed through the displayed month.
  #
  # @return [Integer] The available amount in cents.
  def total_available
    budget.assignable_categories.sum do |category|
      available_for(category)
    end
  end

  # Return the available amount carried in from prior months across every
  # non-inflow category.
  #
  # @return [Integer] The rolled-over amount in cents.
  def total_rollover
    total_available - total_assigned + total_used
  end

  # Return the total used for the displayed month across every
  # non-inflow category.
  #
  # @return [Integer] The used amount in cents.
  def total_used
    budget.assignable_categories.sum do |category|
      snapshot_for(category.id).amount_used
    end
  end

  # Return whether the available amount does not cover the category's
  # upcoming transactions for the displayed month. An already overspent
  # amount is excluded, since the interface signals it in red.
  #
  # @param category [Category] The category to evaluate.
  # @return [Boolean] Whether the upcoming transactions are uncovered.
  def uncovered?(category)
    available = available_for(category)

    !available.negative? && (available + upcoming_for(category)).negative?
  end

  # Return whether the category has a monthly target that has not yet been
  # fully funded for the displayed month, and the available amount is
  # not overspent.
  #
  # @param category [Category] The category to evaluate.
  # @return [Boolean] Whether the category is underfunded.
  def underfunded?(category)
    category.monthly_target? &&
      !available_for(category).negative? &&
      !snoozed?(category) &&
      target_progress_for(category).underfunded?
  end

  # Return the upcoming transaction amount for a category, summed across every
  # transaction dated on or before the end of the displayed month. For a
  # top-level category, sum the upcoming amounts of its subcategories.
  #
  # @param category [Category] The category or category group.
  # @return [Integer] The upcoming amount in cents.
  def upcoming_for(category)
    amount_for(category, upcoming_amounts_by_category)
  end

  # Return the upcoming transactions for a category in the displayed month.
  #
  # @param category [Category] The subcategory to summarize.
  # @return [UpcomingTransactions] The upcoming transactions summary.
  def upcoming_transactions_for(category)
    UpcomingTransactions.new(budget_snapshot: self, category: category)
  end

  private

  attr_reader :budget, :requested_date

  # Return the amount for a category from a hash keyed by category ID. For a
  # top-level category, sum the amounts of its subcategories.
  #
  # @param category [Category] The category or category group.
  # @param amounts [Hash{Integer => Integer}] The amounts by category ID.
  # @return [Integer] The amount in cents.
  def amount_for(category, amounts)
    if category.parent_id.nil?
      category.subcategories.sum { |subcategory| amounts[subcategory.id] || 0 }
    else
      amounts[category.id] || 0
    end
  end

  # Return the values loaded for the displayed month. A snapshot built for a
  # future month is handed the values loaded for that month, so it queries for
  # nothing the displayed month already loaded.
  #
  # @return [BudgetSnapshotMonth] The loaded values for the displayed month.
  def month
    @month ||= BudgetSnapshotMonth.new(budget, date)
  end

  # Return the budget snapshot date, which owns the displayed date and the
  # navigable range of months for this budget.
  #
  # @return [BudgetSnapshotDate] The date navigation for this budget snapshot.
  def snapshot_date
    @snapshot_date ||= BudgetSnapshotDate.new(budget, date: requested_date, snapshot_range: @snapshot_range)
  end

  # Return a hash keyed by category ID of the summed amount of the upcoming
  # transactions dated on or before the end of the displayed month.
  #
  # @return [Hash{Integer => Integer}] The upcoming amount by category ID.
  def upcoming_amounts_by_category
    @upcoming_amounts_by_category ||= budget.transactions
                                            .upcoming
                                            .where(date: ..date.end_of_month)
                                            .reorder(nil)
                                            .group(:category_id)
                                            .sum(:amount)
  end
end
