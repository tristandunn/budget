# frozen_string_literal: true

class Category < ApplicationRecord
  belongs_to :budget
  belongs_to :parent, class_name: "Category", optional: true

  has_many :snapshots, class_name: "CategorySnapshot", dependent: :destroy
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :transactions, inverse_of: :subcategory, dependent: :nullify

  validates :name, presence:   true,
                   uniqueness: { case_sensitive: false, scope: :budget_id }
  validates :position, presence: true, numericality: { only_integer: true }
end
