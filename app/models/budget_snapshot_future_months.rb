# frozen_string_literal: true

class BudgetSnapshotFutureMonths
  LIMIT = 6

  # Initialize the future months for a budget snapshot.
  #
  # @param budget [Budget] The budget to summarize.
  # @param available_amounts [Hash{Integer => Integer}] The available amount by category ID through the displayed month.
  # @param date [Date] The displayed month.
  # @param monthly_target_categories [ActiveRecord::Relation] The subcategories with a monthly target.
  # @param snapshot_range [Range<Date>] The known range of navigable months.
  def initialize(budget, available_amounts:, date:, monthly_target_categories:, snapshot_range:)
    @available_amounts         = available_amounts
    @budget                    = budget
    @date                      = date
    @monthly_target_categories = monthly_target_categories
    @snapshot_range            = snapshot_range
  end

  # Return a budget snapshot per future month that has assignments, capped at
  # `LIMIT` and ordered from the nearest month.
  #
  # Every month is preloaded from a single range query, so the returned
  # snapshots answer for their own month without querying again.
  #
  # @return [Array<BudgetSnapshot>] The future month snapshots.
  def to_a
    dates.map do |future_date|
      BudgetSnapshot.new(
        budget,
        month:          future_date.month,
        preload:        preload_for(future_date),
        snapshot_range: snapshot_range,
        year:           future_date.year
      )
    end
  end

  private

  attr_reader :available_amounts, :budget, :date, :monthly_target_categories, :snapshot_range

  # Return a hash keyed by month of the available amount by category ID summed
  # across every snapshot up to and including that month.
  #
  # The months are walked in order and each one carries the running total
  # forward, so a month without assignments still moves the amounts it covers
  # even though no snapshot is returned for it.
  #
  # @return [Hash{Date => Hash{Integer => Integer}}] The available amount by category ID, keyed by month.
  def cumulative_amounts
    @cumulative_amounts ||= begin
      running = available_amounts.dup

      snapshots_by_date.transform_values do |snapshots|
        snapshots.each do |snapshot|
          running[snapshot.category_id] = running.fetch(snapshot.category_id, 0) + snapshot.amount_remaining
        end

        running.dup
      end
    end
  end

  # Return the dates of the future months that have assignments, capped at
  # `LIMIT` and ordered from the nearest month.
  #
  # @return [Array<Date>] The future month dates.
  def dates
    @dates ||= budget.category_snapshots
                     .where(date: date.next_month..)
                     .where.not(amount_assigned: 0)
                     .order(:date)
                     .distinct
                     .limit(LIMIT)
                     .pluck(:date)
  end

  # Return the preloaded state for a future month, which is everything the
  # snapshot for that month would otherwise query for itself.
  #
  # @param future_date [Date] The future month.
  # @return [BudgetSnapshot::Preload] The preloaded state for the month.
  def preload_for(future_date)
    BudgetSnapshot::Preload.new(
      available_amounts:         cumulative_amounts[future_date],
      monthly_target_categories: monthly_target_categories,
      snapshots:                 snapshots_by_date[future_date].index_by(&:category_id)
    )
  end

  # Return the category snapshots for every month between the displayed month
  # and the last future month, grouped by month and ordered from the nearest.
  #
  # The range covers every month rather than only the returned ones, since a
  # month without assignments still contributes to the cumulative amounts of
  # the months that follow it.
  #
  # Only a returned month reaches this, so `dates` always has a last month to
  # bound the range with.
  #
  # @return [Hash{Date => Array<CategorySnapshot>}] The category snapshots keyed by month.
  def snapshots_by_date
    @snapshots_by_date ||= budget.category_snapshots
                                 .where(date: date.next_month..dates.last)
                                 .order(:date)
                                 .group_by(&:date)
  end
end
