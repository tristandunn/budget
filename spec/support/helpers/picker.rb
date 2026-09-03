# frozen_string_literal: true

module RSpec
  module Helpers
    module Picker
      # Open the picker panel for the given controller.
      #
      # @param controller [String] The Stimulus controller name.
      # @return [void]
      def open_picker(controller)
        find("[data-action~='click->#{controller}#open']").click
      end

      # Open the picker panel and click the option with the given label.
      #
      # Unlike the `fill_in_` helpers, which script the hidden field, this
      # drives the panel the way a person does, so it exercises the picker's
      # own wiring. Use it in a spec that covers the picker itself.
      #
      # @param controller [String] The Stimulus controller name.
      # @param label [String] The option label to select.
      # @return [void]
      def select_in_picker(controller, label)
        open_picker(controller)

        within "[data-#{controller}-target='picker']" do
          find("[role='option']", text: label).click
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Helpers::Picker, type: :feature
end
