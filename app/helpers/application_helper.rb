# frozen_string_literal: true

module ApplicationHelper
  # Formats an amount in cents as currency.
  #
  # @param cents [Integer] The amount in cents.
  # @return [String] The formatted currency string.
  def number_to_money(cents)
    number_to_currency Money.from_cents(cents)
  end
end
