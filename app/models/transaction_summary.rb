# frozen_string_literal: true

class TransactionSummary
  delegate :size, to: :transactions

  def initialize(budget, ids:)
    @budget = budget
    @ids    = ids
  end

  # Return the amount across the selection.
  #
  # @return [Integer] The summed amount in cents.
  def total
    transactions.sum(:amount)
  end

  # Return the selected transactions, scoped to the budget.
  #
  # @return [ActiveRecord::Relation] The selected transactions.
  def transactions
    @transactions ||= @budget.transactions.where(id: @ids)
  end
end
