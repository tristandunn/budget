# frozen_string_literal: true

module Accounts
  class TransactionsController < ApplicationController
    # Render transactions for a single account grouped by date.
    def index
      @account              = account
      @budget               = budget
      @grouped_transactions = grouped_transactions
    end

    private

    # Return the account for the given `account_id` parameter.
    #
    # @return [Account] The requested account.
    def account
      @account ||= budget.accounts.find(params[:account_id])
    end

    # Return the budget for the given `budget_id` parameter.
    #
    # @return [Budget] The requested budget.
    def budget
      @budget ||= Budget.find(params[:budget_id])
    end

    # Return transactions for the account, grouped by date, optionally
    # excluding reconciled transactions.
    #
    # @return [Hash{Date => Array<Transaction>}] The grouped transactions.
    def grouped_transactions
      transactions = account.transactions.includes(:subcategory)
      transactions = transactions.where.not(status: :reconciled) if budget.settings.hide_reconciled?
      transactions.group_by(&:date)
    end
  end
end
