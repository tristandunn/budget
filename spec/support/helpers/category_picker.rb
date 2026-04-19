# frozen_string_literal: true

module RSpec
  module Helpers
    module CategoryPicker
      # Set the category picker hidden field value, using execute_script for
      # JavaScript-driven tests where the field is not interactable.
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
