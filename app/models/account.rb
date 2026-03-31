# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :budget

  has_many :transactions, dependent: :destroy

  validates :balance, numericality: { only_integer: true }
  validates :name,    presence:   true,
                      uniqueness: { case_sensitive: false, scope: :budget_id }

  default_scope { order(:name) }

  scope :cash,   -> { where(credit: false) }
  scope :credit, -> { where(credit: true) }

  # Return the balance minus pending transaction amounts.
  #
  # @return [Integer] The cleared balance in cents.
  def cleared_balance
    balance - uncleared_balance
  end

  # Return the sum of pending transaction amounts.
  #
  # @return [Integer] The uncleared balance in cents.
  def uncleared_balance
    transactions.pending.sum(:amount)
  end
end
