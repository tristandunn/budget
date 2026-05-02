# frozen_string_literal: true

class TransfersController < ApplicationController
  # Render the new transfer form.
  def new
    @form     = TransferForm.new(budget: budget, to_account: default_to_account)
    @budget   = budget
    @accounts = budget.accounts.to_a
  end

  # Create a transfer between two accounts.
  def create
    @form     = TransferForm.new(transfer_parameters)
    @budget   = budget
    @accounts = budget.accounts.to_a

    if @form.save
      redirect_to budget_account_transactions_path(budget, to_account), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  protected

  # Return the budget for the given `budget_id` parameter.
  #
  # @return [Budget] The requested budget.
  def budget
    @budget ||= Budget.find(params[:budget_id])
  end

  # Return the default destination account from the query parameter, if present.
  #
  # @return [Account] The requested credit destination account.
  # @return [nil] When no destination account is provided or it does not resolve to a credit account.
  def default_to_account
    if params[:to_account_id].present?
      budget.accounts.credit.find_by(id: params[:to_account_id])
    end
  end

  # Return the source account for the transfer.
  #
  # @return [Account] The requested source account.
  # @return [nil] When no source account is provided or it does not exist.
  def from_account
    budget.accounts.find_by(id: parameters[:from_account_id])
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
    if defined?(@to_account)
      @to_account
    else
      @to_account = budget.accounts.find_by(id: parameters[:to_account_id])
    end
  end

  # Return the permitted parameters merged with budget and resolved accounts.
  #
  # @return [Hash] The permitted parameters merged with the budget and accounts.
  def transfer_parameters
    {
      amount:       parameters[:amount],
      budget:       budget,
      date:         parameters[:date],
      from_account: from_account,
      memo:         parameters[:memo],
      to_account:   to_account
    }
  end
end
