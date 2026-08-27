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

  # Return the available amount projected forward by the upcoming total.
  # Upcoming transactions have no balance effect until activation, so the
  # snapshot's available amount excludes them and this adds the two together.
  #
  # @return [Integer] The projected available amount in cents.
  def available_after
    budget_snapshot.available_for(category) + total
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

  # Return the amounts of the category's upcoming transactions dated on or
  # before the end of the displayed month, loaded in a single query. The
  # available amount is cumulative through the displayed month, so anything
  # still awaiting activation from an earlier month affects it too.
  #
  # @return [Array<Integer>] The upcoming amounts in cents.
  def amounts
    @amounts ||= category.transactions
                         .upcoming
                         .where(date: ..budget_snapshot.date.end_of_month)
                         .reorder(nil)
                         .pluck(:amount)
  end
end
