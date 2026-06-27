# frozen_string_literal: true

class Category < ApplicationRecord
  AVAILABLE_TO_ASSIGN  = "Available to Assign"
  INFLOW               = "Inflow"
  INFLOW_NAMES         = [AVAILABLE_TO_ASSIGN, INFLOW].freeze
  MONTHLY_TARGET_TYPES = %w(monthly_spending monthly_savings).freeze

  belongs_to :budget
  belongs_to :parent, class_name: "Category", optional: true

  has_many :snapshots, class_name: "CategorySnapshot", dependent: :destroy
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :transactions, inverse_of: :subcategory, dependent: :nullify

  enum :target_type,
       { monthly_spending: 0, monthly_savings: 1 },
       prefix:   :target_type,
       validate: { allow_nil: true }

  normalizes :name, with: ->(value) { value.strip }

  validates :name,          presence:   true,
                            uniqueness: { case_sensitive: false, scope: %i(budget_id parent_id) }
  validates :position,      presence:     true,
                            numericality: { only_integer: true }
  validates :target_amount, presence:     true,
                            numericality: { greater_than: 0, only_integer: true },
                            if:           :target_type?

  scope :with_monthly_target, -> { where(target_type: MONTHLY_TARGET_TYPES) }

  # Returns true if this category is an inflow category.
  #
  # @return [Boolean] Whether this category is an inflow category.
  def inflow?
    name.to_s.downcase.in?(INFLOW_NAMES.map(&:downcase))
  end

  # Returns true when the category has a per-month funding target, as opposed
  # to no target.
  #
  # @return [Boolean] Whether the category has a monthly funding target.
  def monthly_target?
    target_type.in?(MONTHLY_TARGET_TYPES)
  end

  # Returns subcategories sorted by position.
  #
  # @return [Array<Category>] The subcategories sorted by position.
  def subcategories_by_position
    subcategories.sort_by(&:position)
  end
end
