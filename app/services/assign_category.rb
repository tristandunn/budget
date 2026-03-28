# frozen_string_literal: true

class AssignCategory
  # Initialize the service.
  #
  # @param amount [Money] The amount to assign.
  # @param budget [Budget] The budget to update.
  # @param date [Date] The month to assign for.
  # @param subcategory [Category] The subcategory to assign to.
  def initialize(amount:, budget:, date:, subcategory:)
    @budget      = budget
    @subcategory = subcategory
    @amount      = amount.cents
    @date        = date.beginning_of_month
  end

  # Assign the amount to the subcategory and update related balances.
  #
  # @param amount [Money] The amount to assign.
  # @param budget [Budget] The budget to update.
  # @param date [Date] The month to assign for.
  # @param subcategory [Category] The subcategory to assign to.
  # @return [Boolean] Whether the assignment was saved successfully.
  def self.call(amount:, budget:, date:, subcategory:)
    new(budget: budget, subcategory: subcategory, amount: amount, date: date).call
  end

  # Assign the amount to the subcategory and update related balances.
  #
  # @return [Boolean] Whether the assignment was saved successfully.
  def call
    budget.with_lock do
      delta = amount - subcategory_snapshot.amount_assigned

      subcategory_snapshot.update!(amount_assigned: amount)
      category_snapshot.increment!(:amount_assigned, delta)
      budget.increment!(:available_to_assign, -delta)

      true
    end
  end

  private

  attr_reader :amount, :budget, :date, :subcategory

  # Find or create the parent category snapshot for the month.
  #
  # @return [CategorySnapshot] The snapshot for the parent category.
  def category_snapshot
    @category_snapshot ||= subcategory.parent.snapshots.find_or_create_by!(
      budget: budget,
      date:   date
    )
  end

  # Find or create the subcategory snapshot for the month.
  #
  # @return [CategorySnapshot] The snapshot for the subcategory.
  def subcategory_snapshot
    @subcategory_snapshot ||= subcategory.snapshots.find_or_create_by!(
      budget: budget,
      date:   date
    )
  end
end
