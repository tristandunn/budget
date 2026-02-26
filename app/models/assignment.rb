# frozen_string_literal: true

class Assignment
  include ActiveModel::Model

  attr_accessor :amount, :budget, :date, :subcategory

  validates :amount, numericality: { only_integer: true }
end
