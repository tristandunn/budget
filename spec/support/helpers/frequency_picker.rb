# frozen_string_literal: true

module RSpec
  module Helpers
    module FrequencyPicker
      # Set the frequency picker hidden field value without opening the picker.
      #
      # The hidden field is not interactable, so a JavaScript-driven test
      # scripts its value rather than opening the panel and clicking an
      # option. That bypasses the picker entirely, so use this in a spec whose
      # subject is something else and drive the panel itself in a spec that
      # covers the picker.
      #
      # @param value [String, Symbol] The frequency value to select.
      # @return [void]
      def fill_in_frequency(value)
        field = find("[data-frequency-picker-target='hiddenField']", visible: false)

        if Capybara.current_driver == Capybara.javascript_driver
          page.execute_script("arguments[0].value = arguments[1]", field, value.to_s)
        else
          field.set(value.to_s)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Helpers::FrequencyPicker, type: :feature
end
