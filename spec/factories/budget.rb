# frozen_string_literal: true

FactoryBot.define do
  factory :budget do
    users { [user] }

    sequence(:name) { |n| "Budget #{n}" }

    transient do
      user { association(:user) }
    end
  end
end
