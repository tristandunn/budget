# frozen_string_literal: true

module BudgetHelper
  # Returns the CSS classes for a category based on the amount remaining in the snapshot.
  #
  # @return [String] A string representing the CSS classes for the given snapshot.
  def snapshot_color(snapshot)
    if snapshot.amount_remaining.zero?
      "bg-stone-200 text-stone-950"
    elsif snapshot.amount_remaining.negative?
      "bg-red-200 text-red-950"
    else
      "bg-lime-400 text-lime-950"
    end
  end
end
