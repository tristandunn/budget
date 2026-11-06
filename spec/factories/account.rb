# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    budget

    sequence(:name) { |number| "Account #{number}" }

    balance { Faker::Number.number(digits: 5) }
    credit  { false }

    trait :credit do
      credit { true }
    end
  end
end
