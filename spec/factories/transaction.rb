# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    budget
    account     { association(:account, budget: budget) }
    payee       { association(:payee, budget: budget) }
    subcategory { association(:category, :subcategory, budget: budget) }

    amount { Faker::Number.number }
    date   { Date.current }

    trait :cleared do
      status { :cleared }
    end

    trait :reconciled do
      status { :reconciled }
    end

    trait :recurring do
      date      { 1.month.from_now.to_date }
      frequency { :monthly }
      status    { :upcoming }
    end

    trait :upcoming do
      date   { 1.month.from_now.to_date }
      status { :upcoming }
    end
  end
end
