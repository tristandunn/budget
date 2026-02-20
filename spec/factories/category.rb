# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    budget

    sequence(:name) { |n| "Category #{n}" }

    transient do
      with_snapshot { true }
    end

    trait :subcategory do
      parent { association(:category, budget: budget) }
    end

    trait :inflow do
      name          { Category::INFLOW }
      with_snapshot { false }
    end

    trait :inflow_subcategory do
      parent { association(:category, :inflow, budget: budget) }

      name          { Category::AVAILABLE_TO_ASSIGN }
      with_snapshot { false }
    end

    after(:create) do |category, context|
      if context.with_snapshot
        create(:category_snapshot, category: category, budget: category.budget)
      end
    end
  end
end
