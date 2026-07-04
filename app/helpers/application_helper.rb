# frozen_string_literal: true

module ApplicationHelper
  # Formats an amount in cents as currency.
  #
  # @param cents [Integer] The amount in cents.
  # @return [String] The formatted currency string.
  def number_to_money(cents)
    number_to_currency Money.from_cents(cents)
  end

  # Builds the browser title, suffixing any per-page title with the app name.
  #
  # @return [String] The page title.
  def page_title
    if content_for?(:title)
      "#{content_for(:title)} - #{t("title")}"
    else
      t("title")
    end
  end
end
