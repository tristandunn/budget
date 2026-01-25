# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :budget
  belongs_to :subcategory, class_name:  "Category",
                           foreign_key: :category_id,
                           inverse_of:  :transactions

  validates :amount, presence: true, numericality: { only_integer: true }
  validate  :validate_subcategory

  private

  # Validate that the subcategory is a subcategory.
  #
  # @return [void]
  def validate_subcategory
    if subcategory&.parent.blank?
      errors.add(:subcategory, :not_a_subcategory)
    end
  end
end
