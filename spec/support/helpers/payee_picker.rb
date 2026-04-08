# frozen_string_literal: true

module RSpec
  module Helpers
    module PayeePicker
      # Set the payee picker hidden field value, using execute_script for
      # JavaScript-driven tests where the field is not interactable.
      #
      # @param name [String] The payee name to set.
      # @return [void]
      def fill_in_payee(name)
        field = find("[data-payee-picker-target='hiddenField']", visible: false)

        if Capybara.current_driver == Capybara.javascript_driver
          page.execute_script("arguments[0].value = arguments[1]", field, name)
        else
          field.set(name)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Helpers::PayeePicker, type: :feature
end
