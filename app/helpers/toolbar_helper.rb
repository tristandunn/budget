# frozen_string_literal: true

module ToolbarHelper
  DEFAULT_CLASSES = "flex flex-col items-center py-4 px-4"

  # Returns the CSS classes for a toolbar item.
  #
  # @param active [Boolean] Whether the item is active.
  # @return [String] The CSS classes for the toolbar item.
  def toolbar_item_class(active:)
    if active
      "#{DEFAULT_CLASSES} text-slate-800"
    else
      "#{DEFAULT_CLASSES} text-slate-400 hover:text-slate-600"
    end
  end
end
