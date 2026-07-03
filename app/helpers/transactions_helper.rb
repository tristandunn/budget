# frozen_string_literal: true

module TransactionsHelper
  # Returns the last-reconciled summary label for an account, describing when it
  # was last reconciled or that it never has been.
  #
  # @param account [Account] The account to summarize.
  # @return [String] The reconciled summary label.
  def account_reconciled_summary(account)
    if account.last_reconciled_at
      t("accounts.transactions.reconcile.reconciled",
        time: relative_time(account.last_reconciled_at.to_date))
    else
      t("accounts.transactions.reconcile.reconciled_never")
    end
  end

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

  # Returns a lowercase relative time label for the given date, such as
  # "today", "yesterday", "3 days ago", "1 week ago", or "2 months ago".
  #
  # @param date [Date] The date to describe.
  # @return [String] A relative time label.
  def relative_time(date)
    days = (Date.current - date).to_i

    case days
    when 0      then t("dates.today").downcase
    when 1      then t("dates.yesterday").downcase
    when 2..6   then t("dates.days_ago", count: days)
    when 7..27  then t("dates.weeks_ago", count: days.days.in_weeks.to_i)
    else             t("dates.months_ago", count: days.days.in_months.ceil)
    end
  end

  # Returns the category label for a transaction, falling back to a
  # credit card payment label for transfers since they have no subcategory.
  #
  # @param transaction [Transaction] The transaction to label.
  # @return [String, nil] The category label, or nil when absent.
  def transaction_category(transaction)
    if transaction.transfer?
      t("transactions.transfer_category")
    else
      transaction.subcategory&.name
    end
  end

  # Wraps content in a link to the transaction edit page, or a plain div if
  # the transaction is reconciled.
  #
  # @param transaction [Transaction] The transaction to wrap.
  # @return [String] The wrapped HTML content.
  def transaction_row_wrapper(transaction, &)
    classes = "flex min-w-0 flex-1 flex-col gap-0.5"

    if transaction.reconciled?
      tag.div(class: classes, &)
    else
      tag.a(class: classes,
            href:  edit_budget_transaction_path(transaction.budget, transaction),
            data:  { turbo_frame: "transaction_dialog" },
            &)
    end
  end
end
