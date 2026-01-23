# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    budget

    name { Faker::Commerce.unique.department }

    transient do
      with_snapshot { true }
    end

    trait :subcategory do
      parent { association(:category, budget: budget) }
    end

    after(:create) do |category, context|
      if context.with_snapshot
        category.snapshots.find_or_create_by(
          budget: category.budget,
          date:   Date.current.beginning_of_month
        )
      end
    end
  end
end
