# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    budget
    account     { association(:account, budget: budget) }
    subcategory { association(:category, :subcategory, budget: budget) }

    amount { Faker::Number.number }
  end
end
