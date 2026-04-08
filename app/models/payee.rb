# frozen_string_literal: true

class Payee < ApplicationRecord
  belongs_to :budget

  has_many :transactions, dependent: :restrict_with_error

  validates :name, presence:   true,
                   uniqueness: { scope: :budget_id }
end
