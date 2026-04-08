# frozen_string_literal: true

FactoryBot.define do
  factory :payee do
    budget
    sequence(:name) { |n| "Payee #{n}" }
  end
end
