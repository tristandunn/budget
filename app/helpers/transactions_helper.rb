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
            data:  { turbo_frame: "transaction_dialog" },
            &)
    end
  end
end
