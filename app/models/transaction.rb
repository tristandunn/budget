# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :budget
  belongs_to :category

  validates :amount, presence: true, numericality: { only_integer: true }
end
