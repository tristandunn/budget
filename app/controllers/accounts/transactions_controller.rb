# frozen_string_literal: true

module Accounts
  class TransactionsController < ApplicationController
    # Render transactions for a single account grouped by date.
    def index
      @account = account
      @budget  = current_budget
      @scheduled_transactions, @current_transactions = filtered_transactions
    end

    private

    # Return the account for the given `account_id` parameter.
    #
    # @return [Account] The requested account.
    def account
      @account ||= current_budget.accounts.find(params.expect(:account_id))
    end

    # Return transactions for the account, grouped by upcoming or not,
    # optionally excluding reconciled transactions.
    #
    # @return [Array(Array<Transaction>, Array<Transaction>)] The upcoming and current transactions.
    def filtered_transactions
      transactions = account.transactions.recent.includes(:payee, :subcategory)
      transactions = transactions.where.not(status: :reconciled) if current_budget.settings.hide_reconciled?
      transactions.partition(&:upcoming?)
    end
  end
end
