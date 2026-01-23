# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    budget

    name { Faker::Commerce.unique.department }

    trait :subcategory do
      parent { association(:category, budget: budget) }
    end
  end
end
