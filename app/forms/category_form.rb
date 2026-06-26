# frozen_string_literal: true

class CategoryForm < BaseForm
  attr_accessor :category, :name

  validate :validate_category

  # Build a form prepopulated from an existing category.
  #
  # @param category [Category] The category to prepopulate from.
  # @return [CategoryForm] The prepopulated form.
  def self.from(category:)
    new(category: category, name: category.name)
  end

  # Attempt to update the category if the form is valid.
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
    { name: name }
  end

  # Validate the category, merging its errors into the form.
  #
  # @return [void]
  def validate_category
    if category.invalid?
      errors.merge!(category.errors)
    end
  end
end
