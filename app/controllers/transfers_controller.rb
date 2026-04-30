# frozen_string_literal: true

class TransfersController < ApplicationController
  # Render the new transfer form.
  def new
    @form     = TransferForm.new(budget: budget)
    @budget   = budget
    @accounts = budget.accounts
  end

  # Create a transfer between two accounts.
  def create
    @form     = TransferForm.new(form_attributes)
    @budget   = budget
    @accounts = budget.accounts

    if @form.save
      redirect_to budget_transactions_path(budget), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  protected

  # Return the budget for the given budget_id parameter.
  #
  # @return [Budget] The requested budget.
  def budget
    @budget ||= Budget.find(params[:budget_id])
  end

  # Return the attributes used to construct the form, with accounts
  # resolved to records.
  #
  # @return [Hash] The form attributes.
  def form_attributes
    form_parameters
      .except(:from_account_id, :to_account_id)
      .merge(
        budget:       budget,
        from_account: from_account,
        to_account:   to_account
      )
  end

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    @form_parameters ||= params.expect(
      transfer_form: %i(from_account_id to_account_id amount date memo)
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
end
