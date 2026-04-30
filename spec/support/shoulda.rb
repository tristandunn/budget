# frozen_string_literal: true

require "shoulda-matchers"

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.library :rails
    with.test_framework :rspec
  end
end

RSpec.configure do |config|
  config.include(Shoulda::Matchers::ActiveModel, type: :form)
end
