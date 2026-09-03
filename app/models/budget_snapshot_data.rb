# frozen_string_literal: true

class BudgetSnapshotData
  FUTURE_MONTH_LIMIT = 6

  attr_reader :date

  # Initialize the loaded data for one month of a budget.
  #
  # Snapshot dates are always the first day of a month, which every writer
  # guarantees, so a month is identified by its date alone. Preloaded values are
  # supplied when a month is loaded as part of a set, which is how the future
  # months of a month are built, so the whole set costs a handful of queries
  # rather than a few per month.
  #
  # @param budget [Budget] The budget the data belongs to.
  # @param date [Date] The first day of the month the data covers.
  # @param available_amounts [Hash{Integer => Integer}, nil] The preloaded available amounts by category ID.
  # @param monthly_target_categories [Enumerable<Category>, nil] The preloaded categories with a monthly target.
  # @param snapshots [Hash{Integer => CategorySnapshot}, nil] The preloaded snapshots by category ID.
  def initialize(budget, date, available_amounts: nil, monthly_target_categories: nil, snapshots: nil)
    @available_amounts         = available_amounts
    @budget                    = budget
    @date                      = date
    @monthly_target_categories = monthly_target_categories
    @snapshots                 = snapshots
  end

  # Return a hash keyed by category ID of the available amount (assigned minus
  # used) summed across every snapshot up to and including this month.
  #
  # @return [Hash{Integer => Integer}] The available amount by category ID.
  def available_amounts
    @available_amounts ||= budget.category_snapshots
                                 .where(date: ..date)
                                 .group(:category_id)
                                 .sum("amount_assigned - amount_used")
  end

  # Return the data for the future months that have assignments, capped at
  # `FUTURE_MONTH_LIMIT` and ordered from the nearest month. Each month is
  # handed the values loaded for it here, so the whole set is loaded together.
  #
  # @return [Array<BudgetSnapshotData>] The data for each future month.
  def future_months
    @future_months ||= future_month_dates.map do |future_date|
      self.class.new(
        budget,
        future_date,
        available_amounts:         cumulative_available_amounts.fetch(future_date),
        monthly_target_categories: monthly_target_categories,
        snapshots:                 future_snapshots_by_date.fetch(future_date)
      )
    end
  end

  # Return the subcategories that have a monthly funding target.
  #
  # @return [Enumerable<Category>] The categories with a monthly target.
  def monthly_target_categories
    @monthly_target_categories ||= budget.subcategories.with_monthly_target
  end

  # Return this month's category snapshots, indexed by category ID.
  #
  # @return [Hash{Integer => CategorySnapshot}] The snapshots indexed by category ID.
  def snapshots
    @snapshots ||= budget.category_snapshots.for_month(date).index_by(&:category_id)
  end

  private

  attr_reader :budget

  # Return the available amounts by category ID for every month after this one
  # through the last future month, accumulated forward from this month's
  # amounts. A month without assignments is accumulated too, since a month can
  # carry spending forward without being a future month of its own.
  #
  # @return [Hash{Date => Hash{Integer => Integer}}] The available amounts by category ID, by month.
  def cumulative_available_amounts
    @cumulative_available_amounts ||= begin
      amounts = {}
      running = available_amounts

      future_snapshots_by_date.keys.sort.each do |month_date|
        running = running.merge(remaining_amounts_for(month_date)) do |_category_id, total, remaining|
          total + remaining
        end

        amounts[month_date] = running
      end

      amounts
    end
  end

  # Return the dates of the future months that have assignments, capped at
  # `FUTURE_MONTH_LIMIT` and ordered from the nearest month.
  #
  # @return [Array<Date>] The future month dates.
  def future_month_dates
    @future_month_dates ||= budget.category_snapshots
                                  .where(date: date.next_month..)
                                  .where.not(amount_assigned: 0)
                                  .order(:date)
                                  .distinct
                                  .limit(FUTURE_MONTH_LIMIT)
                                  .pluck(:date)
  end

  # Return every category snapshot from the month after this one through the
  # last future month, loaded in a single query.
  #
  # @return [Array<CategorySnapshot>] The future category snapshots.
  def future_snapshots
    budget.category_snapshots.where(date: date.next_month..future_month_dates.last).to_a
  end

  # Return the future category snapshots indexed by category ID and grouped by
  # month.
  #
  # @return [Hash{Date => Hash{Integer => CategorySnapshot}}] The snapshots by category ID, by month.
  def future_snapshots_by_date
    @future_snapshots_by_date ||= future_snapshots.group_by(&:date).transform_values do |month_snapshots|
      month_snapshots.index_by(&:category_id)
    end
  end

  # Return the remaining amount by category ID for the given future month.
  #
  # @param month_date [Date] The month to return the amounts for.
  # @return [Hash{Integer => Integer}] The remaining amount by category ID.
  def remaining_amounts_for(month_date)
    future_snapshots_by_date.fetch(month_date).transform_values(&:amount_remaining)
  end
end
