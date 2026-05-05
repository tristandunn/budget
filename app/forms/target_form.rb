# frozen_string_literal: true

class TargetForm < BaseForm
  DEFAULT_TARGET_TYPE = "monthly_spending"

  attr_accessor :category, :target_amount, :target_type

  # Build a form pre-populated from an existing category. Categories without
  # a target default to the most common target type so the editor opens to a
  # usable state.
  #
  # @param category [Category] The category to pre-populate from.
  # @return [TargetForm] The pre-populated form.
  def self.from(category:)
    new(
      category:      category,
      target_amount: category.target_amount,
      target_type:   category.target_type || DEFAULT_TARGET_TYPE
    )
  end

  # Return the target amount formatted as the decimal string shown in the
  # form input. Returns nil when the amount is missing or zero so the input
  # renders blank and the placeholder is visible.
  #
  # @return [String, nil] The decimal string representation of the amount.
  def target_amount_input
    if target_amount.to_i.positive?
      Money.new(target_amount).to_s
    end
  end

  # Parse a decimal input string into cents and store it as the target amount.
  #
  # A blank value clears the amount so validation can surface a presence error.
  #
  # @param value [String] The raw input string.
  def target_amount_input=(value)
    self.target_amount = if value.present?
                           Money.from_amount(BigDecimal(value)).cents
                         end
  end

  # Attempt to update the category with the form attributes.
  #
  # @return [Boolean] Whether the category was updated successfully.
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

  # Validate the underlying category, merging its errors back into the form.
  #
  # @return [Boolean] Whether the category is valid.
  def valid?(context = nil)
    category.valid?(context).tap do
      errors.merge!(category.errors)
    end
  end
end
