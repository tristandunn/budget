# frozen_string_literal: true

module SidebarHelper
  SIDEBAR_ACCOUNT_CLASSES =
    "flex items-center justify-between gap-2 rounded-lg py-1.5 pr-2 pl-7 text-sm no-underline text-white"
  SIDEBAR_ITEM_CLASSES = "flex items-center gap-3 rounded-lg px-3 py-2 no-underline text-white"

  # Returns whether the sidebar account link is active.
  #
  # @param account [Account] The account to check.
  # @return [Boolean] Whether the account is currently active.
  def sidebar_account_active?(account)
    controller_path == "accounts/transactions" &&
      params[:account_id].to_s == account.id.to_s
  end

  # Returns the CSS classes for a sidebar account link.
  #
  # @param active [Boolean] Whether the account is active.
  # @return [String] The CSS classes for the account link.
  def sidebar_account_class(active:)
    class_names(SIDEBAR_ACCOUNT_CLASSES, { "bg-indigo-800" => active, "hover:bg-white/5" => !active })
  end

  # Returns the CSS classes for a sidebar item.
  #
  # @param active [Boolean] Whether the item is active.
  # @return [String] The CSS classes for the sidebar item.
  def sidebar_item_class(active:)
    class_names(SIDEBAR_ITEM_CLASSES, { "bg-indigo-800" => active, "hover:bg-white/5" => !active })
  end
end
