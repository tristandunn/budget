# frozen_string_literal: true

class ActivateUpcomingTransactionsJob < ApplicationJob
  # Activate all upcoming transactions that are due.
  #
  # @return [void]
  def perform
    Transaction.activation_due.find_each do |transaction|
      if transaction.frequency.present?
        PostRecurringTransaction.call(transaction: transaction)
      else
        ActivateTransaction.call(transaction: transaction)
      end
    end
  end
end
