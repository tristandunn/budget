# frozen_string_literal: true

FactoryBot.define do
  factory :category_snapshot do
    budget   { category.budget }
    category { association(:category, with_snapshot: false) }

    amount_assigned { Faker::Number.number }
    amount_used     { Faker::Number.number }
    date            { Date.current.beginning_of_month }

    trait :for_subcategory do
      category { association(:category, :subcategory, with_snapshot: false) }
    end
  end
end
