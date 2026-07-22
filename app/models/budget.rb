# frozen_string_literal: true

class Budget < ApplicationRecord
  MAXIMUM_NAME_LENGTH = 64

  delegate :time_zone, :time_zone=, to: :settings

  has_many :accounts, dependent: :destroy
  has_many :categories, -> { where(parent_id: nil) }, inverse_of: :budget, dependent: :destroy
  has_many :category_snapshots, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :payees, dependent: :destroy
  has_many :subcategories, -> { where.not(parent_id: nil) },
           class_name: "Category", dependent: :destroy, inverse_of: :budget
  has_many :transactions, dependent: :destroy
  has_many :users, through: :memberships

  validates :available_to_assign, numericality: { only_integer: true }
  validates :name,                presence: true,
                                  length:   { maximum: MAXIMUM_NAME_LENGTH }
  validates :users, presence: true, on: :create

  normalizes :name, with: ->(value) { value.strip }

  # Return the top-level categories that can hold assignments, excluding inflow
  # categories, sorted by position.
  #
  # @return [Array<Category>] The non-inflow top-level categories sorted by position.
  def assignable_categories
    @assignable_categories ||= categories.reject(&:inflow?).sort_by(&:position)
  end

  # Return the combined balance of every account.
  #
  # @return [Integer] The working balance in cents.
  def balance
    @balance ||= accounts.sum(:balance)
  end

  # Return the combined balance minus pending transaction amounts.
  #
  # @return [Integer] The cleared balance in cents.
  def cleared_balance
    balance - uncleared_balance
  end

  # Return the settings for this budget.
  #
  # @return [Settings] The budget settings.
  def settings
    @settings ||= Settings.new(self)
  end

  # Return the combined sum of pending transaction amounts.
  #
  # @return [Integer] The uncleared balance in cents.
  def uncleared_balance
    @uncleared_balance ||= transactions.pending.sum(:amount)
  end
end
