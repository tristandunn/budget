# frozen_string_literal: true

class TargetForm < BaseForm
  DEFAULT_TARGET_TYPE = "monthly_spending"

  attr_accessor :category, :target_amount, :target_type

  validate :validate_category

  # Build a form prepopulated from an existing category. Categories without
  # a target default to the most common target type so the editor opens to a
  # usable state.
  #
  # @param category [Category] The category to prepopulate from.
  # @return [TargetForm] The prepopulated form.
  def self.from(category:)
    new(
      category:      category,
      target_amount: category.target_amount,
      target_type:   category.target_type || DEFAULT_TARGET_TYPE
    )
  end

  # Return the target amount formatted as the decimal string shown in the
  # form input.
  #
  # A missing or zero amount yields nil, so the input renders blank and the
  # placeholder is visible.
  #
  # @return [String] The decimal string representation of the amount.
  # @return [nil] When the amount is missing or zero.
  def target_amount_input
    if target_amount.to_i.positive?
      Money.new(target_amount).to_s
    end
  end

  # Parse a decimal input string into cents and store it as the target amount.
  #
  # Currency formatting characters are stripped before parsing. A blank or
  # unparseable value clears the amount so validation can surface a presence
  # error rather than raising.
  #
  # @param value [String, nil] The raw input string.
  # @return [void]
  def target_amount_input=(value)
    amount = BigDecimal(value.to_s.delete("$,"), exception: false)

    self.target_amount = if amount
                           Money.from_amount(amount).cents
                         end
  end

  # Attempt to update the category with the form attributes.
  #
  # @return [Boolean] Whether the category was updated successfully.
  # @return [nil] When the form is invalid.
  def update
    category.assign_attributes(attributes)

    if valid?
      category.save!
    end
  end

  private

  # Return the form attributes as a hash for updating the category.
  #
  # @return [Hash] The category attributes.
  def attributes
    { target_amount: target_amount, target_type: target_type }
  end

  # Validate the underlying category, merging its errors into the form.
  #
  # @return [void]
  def validate_category
    if category.invalid?
      errors.merge!(category.errors)
    end
  end
end
