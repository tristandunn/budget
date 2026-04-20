# frozen_string_literal: true

class AccountsController < ApplicationController
  # Render the accounts index.
  def index
    @budget = Budget.find(params[:budget_id])

    respond_to do |format|
      format.html do
        @cash_accounts   = @budget.accounts.cash.load
        @credit_accounts = @budget.accounts.credit.load
      end
      format.json do
        render json: @budget.accounts.reorder(:credit, :name).as_json(only: %i(id name credit))
      end
    end
  end
end
