# frozen_string_literal: true

class TransactionsController < ApplicationController
  # Render the new transaction form.
  def new
    @accounts      = budget.accounts
    @form          = TransactionForm.new(budget: budget)
    @subcategories = budget.subcategories
  end

  # Create a new transaction.
  def create
    @accounts      = budget.accounts
    @form          = TransactionForm.new(transaction_parameters)
    @subcategories = budget.subcategories

    if @form.save
      redirect_to budget_path(budget)
    else
      render :new
    end
  end

  protected

  # Return the account for the given `account_id` parameter.
  #
  # @return [Account] The requested account.
  def account
    @account ||= budget.accounts.find(parameters[:account_id])
  end

  # Return the budget for the given `budget_id` parameter.
  #
  # @return [Budget] The requested budget.
  def budget
    @budget ||= Budget.includes(:accounts, :subcategories).find(params[:budget_id])
  end

  # Return the permitted form parameters.
  #
  # @return [ActionController::Parameters] The permitted parameters for the form.
  def parameters
    @parameters ||= params.expect(transaction_form: %i(account_id amount subcategory_id))
  end

  # Return the subcategory for the given `subcategory_id` parameter.
  #
  # @return [Category] The requested subcategory.
  # @return [nil] When no subcategory is provided.
  def subcategory
    @subcategory ||= budget.subcategories.find(parameters[:subcategory_id])
  end

  # Return the permitted parameters with budget and subcategory.
  #
  # @return [Hash] The permitted parameters merged with the budget and subcategory.
  def transaction_parameters
    {
      account:     account,
      amount:      parameters[:amount],
      budget:      budget,
      subcategory: subcategory
    }
  end
end
