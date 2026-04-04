# frozen_string_literal: true

module RSpec
  module Helpers
    module Waiting
      # Wait for an expectation to pass before yielding.
      #
      # @param expectation [RSpec::Matchers] The expectation to wait for.
      # @return [void]
      def wait_for(expectation)
        expect(page).to expectation

        yield
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Helpers::Waiting, type: :feature
end
