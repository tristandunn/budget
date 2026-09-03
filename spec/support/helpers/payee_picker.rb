# frozen_string_literal: true

module RSpec
  module Helpers
    module PayeePicker
      # Set the payee picker hidden field value without opening the picker.
      #
      # The hidden field is not interactable, so a JavaScript-driven test
      # scripts its value rather than opening the panel and clicking an
      # option. That bypasses the picker entirely, so use this in a spec whose
      # subject is something else and drive the panel itself in a spec that
      # covers the picker.
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
