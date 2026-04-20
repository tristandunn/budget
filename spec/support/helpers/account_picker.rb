# frozen_string_literal: true

module RSpec
  module Helpers
    module AccountPicker
      # Set the account picker hidden field value, using execute_script for
      # JavaScript-driven tests where the field is not interactable.
      #
      # @param account [Account] The account to select.
      # @return [void]
      def fill_in_account(account)
        field = find("[data-account-picker-target='hiddenField']", visible: false)

        if Capybara.current_driver == Capybara.javascript_driver
          page.execute_script("arguments[0].value = arguments[1]", field, account.id)
        else
          field.set(account.id)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Helpers::AccountPicker, type: :feature
end
