# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    budget
    account     { association(:account, budget: budget) }
    subcategory { association(:category, :subcategory, budget: budget) }

    amount { Faker::Number.number }
    date   { Date.current }
    payee  { Faker::Name.name }

    trait :cleared do
      status { :cleared }
    end

    trait :reconciled do
      status { :reconciled }
    end

    trait :recurring do
      date      { 1.month.from_now.to_date }
      frequency { :monthly }
    end
  end
end
