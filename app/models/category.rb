# frozen_string_literal: true

class Category < ApplicationRecord
  AVAILABLE_TO_ASSIGN = "Available to Assign"
  INFLOW              = "Inflow"
  INFLOW_NAMES        = [AVAILABLE_TO_ASSIGN, INFLOW].freeze

  belongs_to :budget
  belongs_to :parent, class_name: "Category", optional: true

  has_many :snapshots, class_name: "CategorySnapshot", dependent: :destroy
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :transactions, inverse_of: :subcategory, dependent: :nullify

  validates :name, presence:   true,
                   uniqueness: { case_sensitive: false, scope: %i(budget_id parent_id) }
  validates :position, presence: true, numericality: { only_integer: true }

  # Returns true if this category is an inflow category.
  #
  # @return [Boolean] Whether this category is an inflow category.
  def inflow?
    name.in?(INFLOW_NAMES)
  end

  # Returns subcategories sorted by position.
  #
  # @return [Array<Category>] The subcategories sorted by position.
  def subcategories_by_position
    subcategories.sort_by(&:position)
  end
end
