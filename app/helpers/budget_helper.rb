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

  # Returns the CSS classes for a navigation arrow link.
  #
  # @return [String] A string representing the CSS classes for the navigation arrow link.
  def navigation_arrow_class(disabled)
    class_names("h-5 w-5", "text-taupe-300 pointer-events-none" => disabled)
  end

  # Returns the CSS classes for a subcategory amount in the picker.
  #
  # @return [String] A string representing the CSS classes for the given amount.
  def picker_amount_class(amount)
    if amount.zero?
      "text-gray-400"
    elsif amount.negative?
      "text-gray-900"
    else
      "text-green-600"
    end
  end
end
