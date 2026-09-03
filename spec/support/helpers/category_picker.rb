# frozen_string_literal: true

module RSpec
  module Helpers
    module CategoryPicker
      # Set the category picker hidden field value without opening the picker.
      #
      # The hidden field is not interactable, so a JavaScript-driven test
      # scripts its value rather than opening the panel and clicking an
      # option. That bypasses the picker entirely, so use this in a spec whose
      # subject is something else and drive the panel itself in a spec that
      # covers the picker.
      #
      # @param category [Category] The subcategory to select.
      # @return [void]
      def fill_in_category(category)
        field = find("[data-category-picker-target='hiddenField']", visible: false)

        if Capybara.current_driver == Capybara.javascript_driver
          page.execute_script("arguments[0].value = arguments[1]", field, category.id)
        else
          field.set(category.id)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Helpers::CategoryPicker, type: :feature
end
