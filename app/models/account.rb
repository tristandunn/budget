# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :budget

  default_scope { order(:name) }

  validates :name,    presence:   true,
                      uniqueness: { case_sensitive: false, scope: :budget_id }
  validates :balance, numericality: { only_integer: true }

  scope :cash,   -> { where(credit: false) }
  scope :credit, -> { where(credit: true) }
end
