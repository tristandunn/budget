# frozen_string_literal: true

class ActivateUpcomingTransactionsJob < ApplicationJob
  # Activate all upcoming transactions that are due in each budget's configured
  # time zone.
  #
  # A long-overdue transaction activates one period per run, so the recurring
  # schedule bounds how quickly it catches up. If a transaction fails to
  # activate it is reported and skipped so it does not block the rest of
  # the run.
  #
  # @return [void]
  def perform
    Budget.find_each do |budget|
      Current.set(budget: budget) do
        budget.transactions.activation_due.reorder(nil).find_each do |transaction|
          Rails.error.handle(context: { transaction_id: transaction.id }, severity: :error) do
            activate(transaction)
          end
        end
      end
    end
  end

  private

  # Dispatch a due transaction to the correct activation service.
  #
  # @param transaction [Transaction] The transaction to activate.
  # @return [void]
  def activate(transaction)
    if transaction.frequency.present?
      PostRecurringTransaction.call(transaction: transaction)
    else
      ActivateTransaction.call(transaction: transaction)
    end
  end
end
