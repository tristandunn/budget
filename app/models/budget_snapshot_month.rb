# frozen_string_literal: true

class BudgetSnapshotMonth
  # Initialize the budget snapshot month.
  #
  # The displayed month falls back to the current month when the year and
  # month are missing or do not parse.
  #
  # @param budget [Budget] The budget whose months are navigable.
  # @param month [Integer, String, nil] The month to display.
  # @param snapshot_range [Range<Date>, nil] The known range of navigable months, which avoids a query when supplied.
  # @param year [Integer, String, nil] The year to display.
  def initialize(budget, month: nil, snapshot_range: nil, year: nil)
    @budget         = budget
    @month          = month
    @snapshot_range = snapshot_range
    @year           = year
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
    @date ||= if parsed_date == current_month
                current_month
              else
                parsed_date.clamp(snapshot_range.first, snapshot_range.last)
              end
  end

  # Return whether this is the first month in the navigable range.
  #
  # @return [Boolean] Whether this is the first month in the navigable range.
  def first_month?
    date <= snapshot_range.first
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

  attr_reader :budget, :month, :year

  # Return the beginning of the current month.
  #
  # @return [Date] The first day of the current month.
  def current_month
    @current_month ||= Date.current.beginning_of_month
  end

  # Parse the year and month parameters, falling back to the current month.
  #
  # @return [Date] The parsed date, or the current month if parsing fails.
  def parsed_date
    @parsed_date ||= Date.new(year.to_i, month.to_i)
  rescue Date::Error
    @parsed_date = current_month
  end
end
