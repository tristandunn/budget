# frozen_string_literal: true

class AccountsController < ApplicationController
  # Render the accounts index.
  def index
    @budget          = Budget.find(params[:budget_id])
    @cash_accounts   = @budget.accounts.cash.load
    @credit_accounts = @budget.accounts.credit.load
  end
end
