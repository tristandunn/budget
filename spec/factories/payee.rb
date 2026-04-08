# frozen_string_literal: true

FactoryBot.define do
  factory :payee do
    budget
    name { Faker::Company.name }
  end
end
