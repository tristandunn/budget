# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :budget

  has_many :transactions, dependent: :destroy

  validates :name,    presence:   true,
                      uniqueness: { case_sensitive: false, scope: :budget_id }
  validates :balance, numericality: { only_integer: true }

  default_scope { order(:name) }

  scope :cash,   -> { where(credit: false) }
  scope :credit, -> { where(credit: true) }
end
