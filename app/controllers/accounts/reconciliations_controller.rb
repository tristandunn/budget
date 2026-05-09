# frozen_string_literal: true

module Accounts
  class ReconciliationsController < ApplicationController
    # Reconcile the account by marking all cleared transactions as reconciled.
    def create
      account.transactions.cleared.find_each do |transaction|
        transaction.update!(status: :reconciled)
      end

      redirect_to budget_account_transactions_path(budget, account)
    end

    private

    # Return the account for the given `account_id` parameter.
    #
    # @return [Account] The requested account.
    def account
      @account ||= budget.accounts.find(params.expect(:account_id))
    end

    # Return the budget for the given `budget_id` parameter.
    #
    # @return [Budget] The requested budget.
    def budget
      @budget ||= Budget.find(params.expect(:budget_id))
    end
  end
end
