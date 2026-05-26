# frozen_string_literal: true

FactoryBot.define do
  factory :budget do
    users { [user] }

    transient do
      user { association(:user) }
    end
  end
end
