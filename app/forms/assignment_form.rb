# frozen_string_literal: true

class AssignmentForm < BaseForm
  ARITHMETIC_PATTERN = /[+-]?[\d.]+/
  INVALID_CHARACTERS = /[^\d.+-]/

  attr_accessor :budget, :date, :subcategory
  attr_writer   :amount

  validate :validate_assignment
  validate :validate_date_within_navigable_range

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

  # Return the range of navigable months for the budget.
  #
  # @return [Range<Date>] The range of navigable months.
  def navigable_range
    BudgetSnapshot.new(budget).snapshot_range
  end

  # Parse the amount string into numeric parts, supporting arithmetic expressions.
  #
  # @return [Array<BigDecimal>] The numeric parts of the amount string.
  def parts
    @parts ||= @amount.to_s
                      .gsub(INVALID_CHARACTERS, "")
                      .scan(ARITHMETIC_PATTERN)
                      .filter_map { |part| BigDecimal(part, exception: false) }
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
