# frozen_string_literal: true

class TransfersController < ApplicationController
  # Render the new transfer form.
  def new
    @budget   = budget
    @accounts = budget.accounts
  end

  # Create a transfer between two accounts.
  def create
    CreateTransfer.call(**transfer_parameters)

    redirect_to budget_transactions_path(budget), status: :see_other
  end

  protected

  # Return the budget for the given budget_id parameter.
  #
  # @return [Budget] The requested budget.
  def budget
    @budget ||= Budget.find(params[:budget_id])
  end

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    @form_parameters ||= params.expect(
      transfer: %i(from_account_id to_account_id amount date memo)
    ).to_h.symbolize_keys
  end

  # Return the source account for the transfer.
  #
  # @return [Account] The source account.
  def from_account
    @from_account ||= budget.accounts.find(form_parameters[:from_account_id])
  end

  # Return the destination account for the transfer.
  #
  # @return [Account] The destination account.
  def to_account
    @to_account ||= budget.accounts.find(form_parameters[:to_account_id])
  end

  # Return the keyword arguments for the transfer service.
  #
  # @return [Hash] The transfer service arguments.
  def transfer_parameters
    {
      accounts: { from: from_account, to: to_account },
      amount:   Money.from_amount(form_parameters[:amount].to_d),
      budget:   budget,
      date:     form_parameters[:date],
      memo:     form_parameters[:memo].presence
    }
  end
end
