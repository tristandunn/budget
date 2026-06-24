# frozen_string_literal: true

module Accounts
  class ReconciliationsController < ApplicationController
    # Reconcile the account by marking all cleared transactions as reconciled.
    def create
      # rubocop:disable Rails/SkipsModelValidations
      account.transactions.cleared.update_all(status: :reconciled, updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations

      redirect_to budget_account_transactions_path(current_budget, account)
    end

    private

    # Return the account for the given `account_id` parameter.
    #
    # @return [Account] The requested account.
    def account
      @account ||= current_budget.accounts.find(params.expect(:account_id))
    end
  end
end
