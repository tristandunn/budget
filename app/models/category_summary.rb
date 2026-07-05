# frozen_string_literal: true

class CategorySummary
  delegate :size, to: :categories

  def initialize(budget, budget_snapshot:, ids:, previous_budget_snapshot:)
    @budget                   = budget
    @ids                      = ids
    @budget_snapshot          = budget_snapshot
    @previous_budget_snapshot = previous_budget_snapshot
  end

  # Return the activity this month across the selection.
  #
  # @return [Integer] The summed activity amount.
  def activity
    categories.sum do |category|
      -@budget_snapshot.snapshot_for(category.id).amount_used
    end
  end

  # Return the amount assigned this month across the selection.
  #
  # @return [Integer] The summed assigned amount.
  def assigned
    categories.sum do |category|
      @budget_snapshot.snapshot_for(category.id).amount_assigned
    end
  end

  # Return the amount available across the selection.
  #
  # @return [Integer] The summed available amount.
  def available
    categories.sum do |category|
      @budget_snapshot.available_for(category)
    end
  end

  # Return the selected subcategories, scoped to the budget.
  #
  # @return [ActiveRecord::Relation] The selected subcategories.
  def categories
    @categories ||= @budget.subcategories.where(id: @ids)
  end

  # Return the names of the selected categories.
  #
  # @return [Array<String>] The sorted category names.
  def names
    categories.map(&:name).sort
  end

  # Return the amount left over from the previous month across the selection.
  #
  # @return [Integer] The summed rollover amount.
  def rollover
    categories.sum do |category|
      @previous_budget_snapshot&.available_for(category) || 0
    end
  end
end
