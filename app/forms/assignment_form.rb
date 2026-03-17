# frozen_string_literal: true

class AssignmentForm < BaseForm
  ARITHMETIC_PATTERN = /[+-]?[\d.]+/

  attr_accessor :budget, :date, :subcategory
  attr_writer   :amount

  # Return the amount as a Money object.
  #
  # @return [Money] The parsed amount.
  def amount
    if parts.any?
      Money.from_amount(parts.sum)
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

  # Parse the amount string into numeric parts, supporting arithmetic expressions.
  #
  # @return [Array<BigDecimal>] The numeric parts of the amount string.
  def parts
    @parts ||= @amount.to_s.scan(ARITHMETIC_PATTERN).filter_map do |part|
      BigDecimal(part, exception: false)
    end
  end

  # Validate the assignment, merging errors into the form.
  #
  # @return [Boolean] Whether the assignment is valid.
  def valid?(context = nil)
    assignment.valid?(context).tap do
      errors.merge!(assignment.errors)
    end
  end
end
