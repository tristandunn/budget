# frozen_string_literal: true

class Payee < ApplicationRecord
  belongs_to :budget

  has_many :transactions, dependent: :restrict_with_error

  validates :name, presence:   true,
                   uniqueness: { scope: :budget_id }

  normalizes :name, with: ->(value) { value.strip }

  # Return the account id from the most recent transaction for this payee.
  #
  # @return [Integer] The most recent account id.
  # @return [nil] When the payee has no transactions.
  def previous_account_id
    transactions.reorder(date: :desc, id: :desc).pick(:account_id)
  end

  # Return the subcategory id from the most recent categorized transaction for
  # this payee.
  #
  # @return [Integer] The most recent subcategory id.
  # @return [nil] When the payee has no categorized transactions.
  def previous_subcategory_id
    transactions.where.not(category_id: nil).reorder(date: :desc, id: :desc).pick(:category_id)
  end
end
