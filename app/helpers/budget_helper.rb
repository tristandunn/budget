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

  # Returns the CSS classes for a subcategory's available amount, signaling
  # yellow when a monthly spending target has not yet been fully funded for
  # the displayed month and the available amount has not gone overspent.
  #
  # @return [String] A string representing the CSS classes for the badge.
  def available_color(category, budget_snapshot)
    if budget_snapshot.underfunded?(category)
      "bg-yellow-200 text-yellow-950"
    else
      amount_color(budget_snapshot.available_for(category))
    end
  end

  # Returns the CSS classes for a navigation arrow link.
  #
  # @return [String] A string representing the CSS classes for the navigation arrow link.
  def navigation_arrow_class(disabled)
    class_names("h-5 w-5", "text-taupe-300 pointer-events-none" => disabled)
  end

  # Returns the CSS class for a target's progress icon, signaling lime when
  # fully funded and yellow when underfunded.
  #
  # @param progress [TargetProgress] The progress to evaluate.
  # @return [String] The CSS class for the progress icon.
  def progress_color(progress)
    if progress.funded?
      "text-lime-500"
    else
      "text-yellow-500"
    end
  end

  # Returns the localized label describing a target's progress, used as the
  # accessible name for the progress icon.
  #
  # @param progress [TargetProgress] The progress to describe.
  # @return [String] The localized progress label.
  def progress_label(progress)
    if progress.funded?
      t("categories.show.target.funded_label")
    else
      t("categories.show.target.percent_funded", percentage: progress.funded_percentage)
    end
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
