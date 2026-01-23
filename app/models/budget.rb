# frozen_string_literal: true

class Budget < ApplicationRecord
  has_many :categories, -> { where(parent_id: nil) }, inverse_of: :budget, dependent: :destroy
  has_many :category_snapshots, dependent: :destroy
end
