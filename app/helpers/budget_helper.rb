# frozen_string_literal: true

module BudgetHelper
  # Returns the CSS classes for an amount.
  #
  # @return [String] A string representing the CSS classes for the given amount.
  def amount_color(amount)
    if amount.zero?
      "bg-stone-200 text-stone-950"
    elsif amount.negative?
      "bg-red-200 text-red-950"
    else
      "bg-lime-400 text-lime-950"
    end
  end
end
