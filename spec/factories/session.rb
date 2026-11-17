# frozen_string_literal: true

FactoryBot.define do
  factory :session do
    user

    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent(vendor: :firefox) }
  end
end
