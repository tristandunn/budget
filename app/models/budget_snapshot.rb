# frozen_string_literal: true

class BudgetSnapshot
  FUTURE_MONTH_LIMIT = 6

  delegate :current_month?,
           :date,
           :first_month?,
           :last_month?,
           :next_date,
           :previous_date,
           :snapshot_range,
           to: :snapshot_month

  # Initialize the budget snapshot.
  #
  # The displayed month falls back to the current month when the year and
  # month are missing or do not parse.
  #
  # @param budget [Budget] The budget to summarize.
  # @param month [Integer, String, nil] The month to display.
  # @param snapshot_range [Range<Date>, nil] The known range of navigable months, which avoids a query when supplied.
  # @param year [Integer, String, nil] The year to display.
  def initialize(budget, month: nil, snapshot_range: nil, year: nil)
    @budget         = budget
    @month          = month
    @snapshot_range = snapshot_range
    @year           = year
  end

  # Return the available amount for a category, summed across every snapshot
  # up to and including the displayed month. For a top-level category, sum
  # the available amounts of its subcategories.
  #
  # @param category [Category] The category or category group.
  # @return [Integer] The available amount in cents.
  def available_for(category)
    amount_for(category, available_amounts_by_category)
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
  # monthly targets.
  #
  # @return [Integer] The funded percentage, between 0 and 100.
  def funded_percentage
    total_target = monthly_target_categories.sum(&:target_amount)

    if total_target.positive?
      funded = monthly_target_categories.sum do |category|
        [target_progress_for(category).funded_amount, category.target_amount].min
      end

      (funded * 100 / total_target).clamp(0, 100)
    else
      0
    end
  end

  # Return snapshots for the future months that have assignments, capped at
  # `FUTURE_MONTH_LIMIT` and ordered from the nearest month.
  #
  # @return [Array<BudgetSnapshot>] The future month snapshots.
  def future_months
    @future_months ||= future_month_dates.map do |future_date|
      self.class.new(budget, month: future_date.month, snapshot_range: snapshot_range, year: future_date.year)
    end
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
    snapshot = snapshot_for(category.id)

    TargetProgress.new(
      category: category,
      rollover: rollover_for(category, snapshot),
      snapshot: snapshot
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

  private

  attr_reader :budget, :month, :year

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

  # Return a hash keyed by category ID of the available amount (assigned minus
  # used) summed across every snapshot up to and including the displayed month.
  #
  # @return [Hash{Integer => Integer}] The available amount by category ID.
  def available_amounts_by_category
    @available_amounts_by_category ||= budget.category_snapshots
                                             .where(date: ..date)
                                             .group(:category_id)
                                             .sum("amount_assigned - amount_used")
  end

  # Return the dates of the future months that have assignments, capped at
  # `FUTURE_MONTH_LIMIT` and ordered from the nearest month.
  #
  # @return [Array<Date>] The future month dates.
  def future_month_dates
    budget.category_snapshots
          .where(date: date.next_month..)
          .where.not(amount_assigned: 0)
          .order(:date)
          .distinct
          .limit(FUTURE_MONTH_LIMIT)
          .pluck(:date)
  end

  # Return the subcategories that have a monthly funding target.
  #
  # @return [ActiveRecord::Relation] The categories with a monthly target.
  def monthly_target_categories
    @monthly_target_categories ||= budget.subcategories.with_monthly_target
  end

  # Return the available amount carried in from prior months for the category,
  # derived from the cumulative balance through the displayed month minus the
  # displayed month's own remaining amount.
  #
  # @param category [Category] The category to evaluate.
  # @param snapshot [CategorySnapshot] The displayed-month snapshot.
  # @return [Integer] The rolled-over amount in cents.
  def rollover_for(category, snapshot)
    (available_amounts_by_category[category.id] || 0) - snapshot.amount_remaining
  end

  # Return the budget snapshot month, which owns the displayed month and the
  # navigable range of months for this budget.
  #
  # @return [BudgetSnapshotMonth] The month navigation for this budget snapshot.
  def snapshot_month
    @snapshot_month ||= BudgetSnapshotMonth.new(budget, month: month, snapshot_range: @snapshot_range, year: year)
  end

  # Return the category snapshots for this budget snapshot, indexed by
  # category ID.
  #
  # @return [Hash{Integer => CategorySnapshot}] The category snapshots indexed by category ID.
  def snapshots
    @snapshots ||= budget.category_snapshots.for_month(date).index_by(&:category_id)
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
