# frozen_string_literal: true

class BudgetSnapshotDate
  # Initialize the budget snapshot date.
  #
  # The displayed month falls back to the current month when no date is
  # supplied.
  #
  # @param budget [Budget] The budget whose months are navigable.
  # @param date [Date, nil] The first day of the month to display.
  # @param snapshot_range [Range<Date>, nil] The known range of navigable months, which avoids a query when supplied.
  def initialize(budget, date: nil, snapshot_range: nil)
    @budget         = budget
    @requested_date = date || current_month
    @snapshot_range = snapshot_range
  end

  # Return the first day of the month for the given year and month.
  #
  # Callers fall back to the current month when no date is returned, so a
  # request is never rejected for an unusable month.
  #
  # @param year [String, nil] The year of the month.
  # @param month [String, nil] The month of the year.
  # @return [Date] The first day of the month.
  # @return [nil] When either value is missing, is not a number, or they do not form a month.
  def self.parse(year, month)
    values = [year, month].map do |value|
      Integer(value, 10, exception: false)
    end

    if values.all?
      Date.new(*values)
    end
  rescue Date::Error
    nil
  end

  # Return whether this snapshot is for the current month.
  #
  # @return [Boolean] Whether this snapshot is for the current month.
  def current_month?
    date == current_month
  end

  # Return the date for this budget snapshot.
  #
  # The current month is always inside `snapshot_range`, so clamping it is a
  # no-op and the range is left unqueried in that case.
  #
  # @return [Date] The date for this budget snapshot.
  def date
    @date ||= if requested_date == current_month
                current_month
              else
                requested_date.clamp(snapshot_range.first, snapshot_range.last)
              end
  end

  # Return whether this is the first month in the navigable range.
  #
  # @return [Boolean] Whether this is the first month in the navigable range.
  def first_month?
    date <= snapshot_range.first
  end

  # Return whether this snapshot is for a month after the current month.
  #
  # @return [Boolean] Whether this snapshot is for a future month.
  def future_month?
    date > current_month
  end

  # Return whether this is the last month in the navigable range.
  #
  # @return [Boolean] Whether this is the last month in the navigable range.
  def last_month?
    date >= snapshot_range.last
  end

  # Return the next navigable date, or this month's date when this is the
  # last month.
  #
  # @return [Date] The next navigable date, or this month's date when this is the last month.
  def next_date
    if last_month?
      date
    else
      date.next_month
    end
  end

  # Return the previous navigable date, or this month's date when this is
  # the first month.
  #
  # @return [Date] The previous navigable date, or this month's date when this is the first month.
  def previous_date
    if first_month?
      date
    else
      date.prev_month
    end
  end

  # Return the range of navigable months for this budget, always covering the
  # current month.
  #
  # Any past snapshot extends the lower bound. The upper bound is always one
  # month past the latest month with activity, or one month past the current
  # month when that is later, so `last_month?` and `next_date` allow
  # navigating a single month into the future.
  #
  # @return [Range<Date>] The range of navigable months for this budget.
  def snapshot_range
    @snapshot_range ||= begin
      snapshots = budget.category_snapshots
      earliest  = [snapshots.minimum(:date), current_month].compact.min
      latest    = [snapshots.with_activity.maximum(:date), current_month].compact.max.next_month

      earliest..latest
    end
  end

  private

  attr_reader :budget, :requested_date

  # Return the beginning of the current month.
  #
  # @return [Date] The first day of the current month.
  def current_month
    @current_month ||= Date.current.beginning_of_month
  end
end
