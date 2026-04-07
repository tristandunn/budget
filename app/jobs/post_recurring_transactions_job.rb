# frozen_string_literal: true

class PostRecurringTransactionsJob < ApplicationJob
  # Post all recurring transactions that are due.
  #
  # @return [void]
  def perform
    Transaction.recurring_due.each do |transaction|
      PostRecurringTransaction.call(transaction: transaction)
    end
  end
end
