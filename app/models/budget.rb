# frozen_string_literal: true

class Budget < ApplicationRecord
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
  validates :users, presence: true, on: :create

  # Return the settings for this budget.
  #
  # @return [Settings] The budget settings.
  def settings
    @settings ||= Settings.new(self)
  end
end
