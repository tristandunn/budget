# frozen_string_literal: true

class TransfersController < ApplicationController
  # Render the new transfer form.
  def new
    @accounts = accounts
    @budget   = current_budget
    @form     = TransferForm.new(
      budget:       current_budget,
      from_account: default_from_account,
      to_account:   default_to_account
    )
  end

  # Create a transfer between two accounts.
  def create
    @accounts = accounts
    @budget   = current_budget
    @form     = TransferForm.new(transfer_parameters)

    if @form.save
      redirect_to budget_account_transactions_path(current_budget, to_account), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  # Return the accounts for the current budget.
  #
  # @return [Array<Account>] The accounts for the current budget.
  def accounts
    @accounts ||= current_budget.accounts.to_a
  end

  # Return the default source account, which is the budget's only cash account.
  #
  # @return [Account] The sole cash account.
  # @return [nil] When the budget has zero or multiple cash accounts.
  def default_from_account
    cash_accounts = accounts.reject(&:credit?)

    if cash_accounts.one?
      cash_accounts.first
    end
  end

  # Return the default destination account from the query parameter, if present.
  #
  # @return [Account] The requested credit destination account.
  # @return [nil] When no destination account is provided or it does not resolve to a credit account.
  def default_to_account
    account = find_account(params[:to_account_id])

    if account&.credit?
      account
    end
  end

  # Return the account matching the given identifier.
  #
  # @param id [String, nil] The identifier of the account.
  # @return [Account] The matching account.
  # @return [nil] When no account matches the identifier.
  def find_account(id)
    accounts.find { |account| account.id == id.to_i }
  end

  # Return the source account for the transfer.
  #
  # @return [Account] The requested source account.
  # @return [nil] When no source account is provided or it does not exist.
  def from_account
    find_account(parameters[:from_account_id])
  end

  # Return the permitted form parameters.
  #
  # @return [ActionController::Parameters] The permitted parameters for the form.
  def parameters
    @parameters ||= params.expect(
      transfer_form: %i(amount date from_account_id memo to_account_id)
    )
  end

  # Return the destination account for the transfer.
  #
  # @return [Account] The requested destination account.
  # @return [nil] When no destination account is provided or it does not exist.
  def to_account
    find_account(parameters[:to_account_id])
  end

  # Return the permitted parameters merged with budget and resolved accounts.
  #
  # @return [Hash] The permitted parameters merged with the budget and accounts.
  def transfer_parameters
    {
      amount:       parameters[:amount],
      budget:       current_budget,
      date:         parameters[:date],
      from_account: from_account,
      memo:         parameters[:memo],
      to_account:   to_account
    }
  end
end
