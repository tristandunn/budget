# frozen_string_literal: true

require "faker"

RSpec.configure do |config|
  config.before do
    Faker::UniqueGenerator.clear
  end
end
