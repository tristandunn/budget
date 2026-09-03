# frozen_string_literal: true

module RSpec
  module Helpers
    module AccountPicker
      # Set the account picker hidden field value.
      #
      # @param account [Account] The account to select.
      # @return [void]
      def fill_in_account(account)
        fill_in_account_picker("account-picker", account)
      end

      # Set the from-account picker hidden field value.
      #
      # @param account [Account] The account to select.
      # @return [void]
      def fill_in_from_account(account)
        fill_in_account_picker("from-account-picker", account)
      end

      # Set the to-account picker hidden field value.
      #
      # @param account [Account] The account to select.
      # @return [void]
      def fill_in_to_account(account)
        fill_in_account_picker("to-account-picker", account)
      end

      private

      # Set the picker hidden field value without opening the picker.
      #
      # The hidden field is not interactable, so a JavaScript-driven test
      # scripts its value rather than opening the panel and clicking an
      # option. That bypasses the picker entirely, so use this in a spec whose
      # subject is something else and drive the panel itself in a spec that
      # covers the picker.
      #
      # @param controller [String] The Stimulus controller name.
      # @param account [Account] The account to select.
      # @return [void]
      def fill_in_account_picker(controller, account)
        field = find("[data-#{controller}-target='hiddenField']", visible: false)

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
