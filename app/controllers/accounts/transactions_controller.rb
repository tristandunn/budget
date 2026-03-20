# frozen_string_literal: true

module Accounts
  class TransactionsController < ApplicationController
    # Render transactions for a single account grouped by date.
    def index
      @budget               = Budget.find(params[:budget_id])
      @account              = @budget.accounts.find(params[:account_id])
      @grouped_transactions = @account.transactions
                                      .includes(:subcategory)
                                      .group_by(&:date)
    end
  end
end
