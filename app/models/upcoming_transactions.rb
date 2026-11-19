# frozen_string_literal: true

class UpcomingTransactions
  # Initialize the upcoming transactions.
  #
  # @param budget_snapshot [BudgetSnapshot] The snapshot for the displayed month.
  # @param category [Category] The subcategory to summarize.
  def initialize(budget_snapshot:, category:)
    @budget_snapshot = budget_snapshot
    @category        = category
  end

  # Return whether the category has upcoming transactions affecting the
  # displayed month.
  #
  # @return [Boolean] Whether any upcoming transactions exist.
  def any?
    count.positive?
  end

  # Return the available amount projected forward by the upcoming amount.
  # Upcoming transactions have no balance effect until activation, so the
  # snapshot's available amount excludes them and this adds the two together.
  #
  # The available amount is cumulative through the displayed month, so the
  # projection also includes anything still awaiting activation from an earlier
  # month. Only the count and total are limited to the displayed month.
  #
  # @return [Integer] The projected available amount in cents.
  def available_after
    budget_snapshot.available_for(category) + budget_snapshot.upcoming_for(category)
  end

  # Return the number of upcoming transactions affecting the displayed month.
  #
  # @return [Integer] The upcoming transaction count.
  def count
    amounts.size
  end

  # Return the summed amount of the upcoming transactions. Spending is
  # negative, so an outflow-only month sums to a negative amount.
  #
  # @return [Integer] The summed amount in cents.
  def total
    amounts.sum
  end

  private

  attr_reader :budget_snapshot, :category

  delegate :date, to: :budget_snapshot, private: true

  # Return the amounts of the category's upcoming transactions dated within
  # the displayed month, including projected recurring occurrences.
  #
  # @return [Array<Integer>] The upcoming amounts in cents.
  def amounts
    @amounts ||= current_or_recurring_transactions.flat_map do |transaction|
      transaction.occurrence_dates(within: date.all_month).map do
        transaction.amount
      end
    end
  end

  # Return the category's upcoming transactions that can affect the displayed
  # month. Recurring transactions dated earlier are included so they can be
  # projected forward, but an earlier one-time transaction is left out.
  #
  # @return [ActiveRecord::Relation<Transaction>] The upcoming transactions.
  def current_or_recurring_transactions
    upcoming = category.transactions.upcoming
    upcoming.where(date: date.all_month)
            .or(upcoming.where.not(frequency: nil).where(date: ..date.end_of_month))
  end
end
