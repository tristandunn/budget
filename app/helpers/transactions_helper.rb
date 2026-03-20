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
end
