# frozen_string_literal: true

module TransactionsHelper
  # Returns "Today", "Yesterday", or the long date format for the given date.
  #
  # @param date [Date] The date to format.
  # @return [String] A relative or long-formatted date label.
  def relative_date(date)
    case date
    when Date.current
      t("dates.today")
    when Date.yesterday
      t("dates.yesterday")
    else
      l(date, format: :long)
    end
  end

  # Wraps content in a link to the transaction edit page, or a plain div if
  # the transaction is reconciled.
  #
  # @param transaction [Transaction] The transaction to wrap.
  # @return [String] The wrapped HTML content.
  def transaction_row_wrapper(transaction, &)
    classes = "flex flex-1 flex-col gap-0.5"

    if transaction.reconciled?
      tag.div(class: classes, &)
    else
      tag.a(class: classes,
            href:  edit_budget_transaction_path(transaction.budget, transaction),
            &)
    end
  end
end
