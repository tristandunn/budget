# frozen_string_literal: true

class AssignmentForm < BaseForm
  attr_accessor :budget, :date, :subcategory
  attr_writer   :amount

  # Return the amount as a Money object.
  #
  # @return [Money] The parsed amount.
  def amount
    value = BigDecimal(@amount.to_s, exception: false)

    if value
      Money.from_amount(value)
    end
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

  # Validate the assignment, merging errors into the form.
  #
  # @return [Boolean] Whether the assignment is valid.
  def valid?(context = nil)
    assignment.valid?(context).tap do
      errors.merge!(assignment.errors)
    end
  end
end
