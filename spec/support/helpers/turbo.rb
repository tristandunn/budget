# frozen_string_literal: true

module RSpec
  module Helpers
    module Turbo
      # Returns a matcher for a +turbo-stream+ element.
      #
      # @param [String] action The turbo stream action.
      # @param [String] target The turbo stream target.
      # @return [Capybara::RSpecMatchers::Matchers::HaveSelector]
      def have_turbo_stream_element(action:, target:)
        have_css(turbo_stream_selector(action, target))
      end

      # Returns the markup a single +turbo-stream+ element wraps.
      #
      # Parses with Nokogiri's HTML5 parser, since the HTML4 parser behind
      # Capybara discards the contents of the +template+ holding the payload.
      #
      # @param [String] html The rendered turbo stream markup.
      # @param [String] action The turbo stream action.
      # @param [String] target The turbo stream target.
      # @return [String, nil] The payload, or +nil+ when no stream matches.
      def turbo_stream_content(html, action:, target:)
        Nokogiri::HTML5.fragment(html)
                       .at_css("#{turbo_stream_selector(action, target)} > template")
                       &.inner_html
      end

      private

      # Returns a CSS selector matching a +turbo-stream+ element.
      #
      # @param [String] action The turbo stream action.
      # @param [String] target The turbo stream target.
      # @return [String] The selector.
      def turbo_stream_selector(action, target)
        %(turbo-stream[action="#{action}"][target="#{target}"])
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Helpers::Turbo, type: :view
end
