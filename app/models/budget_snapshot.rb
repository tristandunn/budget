# frozen_string_literal: true

class BudgetSnapshot
  delegate :current_month?,
           :date,
           :first_month?,
           :last_month?,
           :next_date,
           :previous_date,
           :snapshot_range,
           to: :snapshot_month

  def initialize(budget, month: nil, year: nil)
    @budget = budget
    @month  = month
    @year   = year
  end

  # Returns the available amount for a category, summed across every snapshot
  # up to and including the displayed month. For a top-level category, sums
  # the available amounts of its subcategories.
  #
  # @param category [Category] The category or category group.
  # @return [Integer] The available amount in cents.
  def available_for(category)
    if category.parent_id.nil?
      category.subcategories.sum do |subcategory|
        available_amounts_by_category[subcategory.id] || 0
      end
    else
      available_amounts_by_category[category.id] || 0
    end
  end

  # Returns the category snapshot for the given category id, initializing a new
  # one if none exists.
  #
  # @return [CategorySnapshot] The category snapshot for the given category id.
  def snapshot_for(category_id)
    snapshots[category_id] ||= CategorySnapshot.new
  end

  # Returns true when the category currently has a monthly target and the
  # displayed-month snapshot has been snoozed.
  #
  # @param category [Category] The category to evaluate.
  # @return [Boolean] Whether the category is snoozed for the displayed month.
  def snoozed?(category)
    category.monthly_target? && snapshot_for(category.id).snoozed?
  end

  # Returns the target progress for the given category.
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

  # Returns true when the category has a monthly target that has not yet been
  # fully funded for the displayed month and the available amount has not gone
  # overspent.
  #
  # @param category [Category] The category to evaluate.
  # @return [Boolean] Whether the category is underfunded.
  def underfunded?(category)
    category.monthly_target? &&
      !available_for(category).negative? &&
      !snoozed?(category) &&
      target_progress_for(category).underfunded?
  end

  private

  attr_reader :budget, :month, :year

  # Returns a hash of category_id to the available amount (assigned minus used)
  # summed across every snapshot up to and including the displayed month.
  #
  # @return [Hash{Integer => Integer}] Available amount by category id.
  def available_amounts_by_category
    @available_amounts_by_category ||= budget.category_snapshots
                                             .where(date: ..date)
                                             .group(:category_id)
                                             .sum("amount_assigned - amount_used")
  end

  # Returns the available amount carried in from prior months for the category,
  # derived from the cumulative balance through the displayed month minus the
  # displayed month's own remaining amount.
  #
  # @param category [Category] The category to evaluate.
  # @param snapshot [CategorySnapshot] The displayed-month snapshot.
  # @return [Integer] The rolled-over amount in cents.
  def rollover_for(category, snapshot)
    (available_amounts_by_category[category.id] || 0) - snapshot.amount_remaining
  end

  # Returns the budget snapshot month, which owns the displayed month and the
  # navigable range of months for this budget.
  #
  # @return [BudgetSnapshotMonth] The month navigation for this budget snapshot.
  def snapshot_month
    @snapshot_month ||= BudgetSnapshotMonth.new(budget, month: month, year: year)
  end

  # Returns the category snapshots for this budget snapshot, indexed by category id.
  #
  # @return [Hash] The category snapshots indexed by category id.
  def snapshots
    @snapshots ||= budget.category_snapshots.for_month(date).index_by(&:category_id)
  end
end
