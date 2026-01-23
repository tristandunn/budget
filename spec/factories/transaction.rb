# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    budget
    category

    amount { Faker::Number.number }
  end
end
