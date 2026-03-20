# frozen_string_literal: true

class TransactionsController < ApplicationController
  # Render all transactions grouped by date.
  def index
    @budget               = budget
    @grouped_transactions = budget.transactions
                                  .includes(:account, :subcategory)
                                  .group_by(&:date)
  end

  # Render the new transaction form.
  def new
    @accounts   = budget.accounts
    @categories = budget.categories.reject(&:inflow?).sort_by(&:position)
    @form       = TransactionForm.new(budget: budget)
  end

  # Create a new transaction.
  def create
    @accounts   = budget.accounts
    @categories = budget.categories.reject(&:inflow?).sort_by(&:position)
    @form       = TransactionForm.new(transaction_parameters)

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
    @budget ||= Budget.includes(:accounts, categories: :subcategories).find(params[:budget_id])
  end

  # Return the permitted form parameters.
  #
  # @return [ActionController::Parameters] The permitted parameters for the form.
  def parameters
    @parameters ||= params.expect(
      transaction_form: %i(account_id amount date memo payee subcategory_id)
    )
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
      date:        parameters[:date],
      memo:        parameters[:memo],
      payee:       parameters[:payee],
      subcategory: subcategory
    }
  end
end
