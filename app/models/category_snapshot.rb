# frozen_string_literal: true

class CategorySnapshot < ApplicationRecord
  belongs_to :budget
  belongs_to :category

  validates :amount_assigned, numericality: { only_integer: true }
  validates :amount_used,     numericality: { only_integer: true }
  validates :category_id,     uniqueness: { scope: %i(budget_id date) }
  validates :date,            presence: true

  scope :for_month,     ->(month_date) { where(date: month_date.beginning_of_month) }
  scope :with_activity, -> { where.not(amount_assigned: 0).or(where.not(amount_used: 0)) }

  # Returns the amount remaining in the category snapshot.
  #
  # @return [Integer] The amount remaining in the category snapshot.
  def amount_remaining
    amount_assigned - amount_used
  end

  # Returns true when the target for the snapshot's month has been snoozed.
  #
  # @return [Boolean] Whether the snapshot is snoozed.
  def snoozed?
    metadata["snoozed"] == true
  end
end
