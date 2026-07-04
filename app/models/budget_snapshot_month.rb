# frozen_string_literal: true

class BudgetSnapshotMonth
  def initialize(budget, month: nil, snapshot_range: nil, year: nil)
    @budget         = budget
    @month          = month
    @snapshot_range = snapshot_range
    @year           = year
  end

  # Returns true if this snapshot is on the current month.
  #
  # @return [Boolean] Whether this snapshot is on the current month.
  def current_month?
    date == current_month
  end

  # Returns the date for this budget snapshot.
  #
  # @return [Date] The date for this budget snapshot.
  def date
    @date ||= parsed_date.clamp(snapshot_range.first, snapshot_range.last)
  end

  # Returns true if this is the first month in the navigable range.
  #
  # @return [Boolean] Whether this is the first month in the navigable range.
  def first_month?
    date <= snapshot_range.first
  end

  # Returns true if this is the last month in the navigable range.
  #
  # @return [Boolean] Whether this is the last month in the navigable range.
  def last_month?
    date >= snapshot_range.last
  end

  # Returns the next navigable date, or this month's date if on the last month.
  #
  # @return [Date] The next navigable date, or this month's date if on the last month.
  def next_date
    if last_month?
      date
    else
      date.next_month
    end
  end

  # Returns the previous navigable date, or this month's date if on the first month.
  #
  # @return [Date] The previous navigable date, or this month's date if on the first month.
  def previous_date
    if first_month?
      date
    else
      date.prev_month
    end
  end

  # Returns the range of navigable months for this budget.
  #
  # @return [Range<Date>] The range of navigable months for this budget.
  def snapshot_range
    @snapshot_range ||= begin
      assigned = budget.category_snapshots.where.not(amount_assigned: 0)

      earliest = assigned.minimum(:date) || current_month
      latest   = [assigned.maximum(:date), current_month].compact.max.next_month

      earliest..latest
    end
  end

  private

  attr_reader :budget, :month, :year

  # Returns the beginning of the current month.
  #
  # @return [Date] The first day of the current month.
  def current_month
    @current_month ||= Date.current.beginning_of_month
  end

  # Parses the year and month parameters, falling back to the current month.
  #
  # @return [Date] The parsed date, or the current month if parsing fails.
  def parsed_date
    Date.new(year.to_i, month.to_i)
  rescue Date::Error
    current_month
  end
end
