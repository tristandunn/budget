# frozen_string_literal: true

class AssignmentForm < BaseForm
  attr_accessor :budget, :date, :subcategory
  attr_writer   :amount

  validate :validate_assignment
  validate :validate_date_within_navigable_range

  # Return the amount as a Money object.
  #
  # @return [Money] The calculated amount.
  # @return [nil] When the amount is not a supported expression.
  def amount
    if @amount.is_a?(String)
      @amount = CalculateAmount.call(@amount)
    end

    @amount
  end

  # Build the assignment.
  #
  # @return [Assignment] The built assignment record.
  def assignment
    @assignment ||= Assignment.new(
      amount:      amount&.cents,
      budget:      budget,
      date:        date,
      subcategory: subcategory
    )
  end

  # Attempt to save the assignment if it's valid.
  #
  # @return [Boolean] Whether the assignment was saved successfully.
  def save
    if valid?
      AssignCategory.call(budget: budget, subcategory: subcategory, amount: amount, date: date)
    end
  end

  private

  # Return the range of navigable months for the budget.
  #
  # @return [Range<Date>] The range of navigable months.
  def navigable_range
    BudgetSnapshot.new(budget).snapshot_range
  end

  # Validate the assignment, merging its errors into the form.
  #
  # @return [void]
  def validate_assignment
    if assignment.invalid?
      errors.merge!(assignment.errors)
    end
  end

  # Validate that the date falls within the budget's navigable month range, so
  # the write path is bounded the same way the display path is.
  #
  # @return [void]
  def validate_date_within_navigable_range
    unless navigable_range.cover?(date)
      errors.add(:date, :out_of_range)
    end
  end
end
