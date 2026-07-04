# frozen_string_literal: true

class AccountsController < ApplicationController
  # Render the accounts index on mobile or redirect to the transactions
  # on desktop.
  def index
    if request.variant.mobile?
      @budget          = current_budget
      @cash_accounts   = current_budget.accounts.cash.load
      @credit_accounts = current_budget.accounts.credit.load
    else
      redirect_to budget_transactions_path(current_budget)
    end
  end

  # Render the new account form.
  def new
    @budget = current_budget
    @form   = AccountForm.new(budget: current_budget)
  end

  # Render the account edit form.
  def edit
    @budget = current_budget
    @form   = AccountForm.from(account: account)
  end

  # Create a new account from form parameters.
  def create
    @budget = current_budget
    @form   = AccountForm.new(budget: current_budget, **form_parameters)

    if @form.save
      redirect_to budget_accounts_path(current_budget), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  # Update the account from form parameters.
  def update
    @budget = current_budget
    @form   = AccountForm.new(account: account, budget: current_budget, **update_form_parameters)

    if @form.update
      redirect_to budget_account_transactions_path(current_budget, account), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Destroy the account when it has no transactions, otherwise silently
  # redirect back to its transactions without deleting anything.
  def destroy
    if account.transactions.exists?
      redirect_to budget_account_transactions_path(current_budget, account), status: :see_other
    else
      account.destroy!

      redirect_to budget_accounts_path(current_budget), status: :see_other
    end
  end

  private

  # Return the account for the given id parameter.
  #
  # @return [Account] The requested account.
  def account
    @account ||= current_budget.accounts.find(params.expect(:id))
  end

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    params.expect(account_form: %i(name credit)).to_h.symbolize_keys
  end

  # Return the permitted form parameters for an update. The credit value is
  # forced to the persisted value once transactions exist, since the type
  # determines how the balance is interpreted.
  #
  # @return [Hash] The permitted parameters for the update form.
  def update_form_parameters
    form_parameters.tap do |attributes|
      if account.transactions.exists?
        attributes[:credit] = account.credit
      end
    end
  end
end
