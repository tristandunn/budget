# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :store_return_location, only: :edit

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
    @categories = outflow_categories
    @form       = TransactionForm.new(budget: budget)
  end

  # Render the edit transaction form.
  def edit
    @accounts    = budget.accounts
    @categories  = outflow_categories
    @transaction = transaction
    @form        = TransactionForm.from(transaction: transaction)
  end

  # Create a new transaction.
  def create
    @accounts   = budget.accounts
    @categories = outflow_categories
    @form       = TransactionForm.new(transaction_parameters)

    if @form.save
      redirect_to budget_path(budget)
    else
      render :new, status: :unprocessable_content
    end
  end

  # Update an existing transaction.
  def update
    @accounts    = budget.accounts
    @categories  = outflow_categories
    @transaction = transaction
    @form        = TransactionForm.new(transaction_parameters)

    if @form.update(transaction)
      redirect_to return_location
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Destroy an existing transaction.
  def destroy
    DestroyTransaction.call(transaction: transaction)

    redirect_to return_location
  end

  protected

  # Return the account for the given `account_id` parameter.
  #
  # @return [Account] The requested account.
  # @return [nil] When no account is provided.
  def account
    if parameters[:account_id].present?
      @account ||= budget.accounts.find(parameters[:account_id])
    end
  end

  # Return the budget for the given `budget_id` parameter.
  #
  # @return [Budget] The requested budget.
  def budget
    @budget ||= Budget.includes(:accounts, categories: :subcategories).find(params[:budget_id])
  end

  # Return the budget categories excluding inflow, sorted by position.
  #
  # @return [Array<Category>] The sorted non-inflow categories.
  def outflow_categories
    @outflow_categories ||= budget.categories.reject(&:inflow?).sort_by(&:position)
  end

  # Return the permitted form parameters.
  #
  # @return [ActionController::Parameters] The permitted parameters for the form.
  def parameters
    @parameters ||= params.expect(
      transaction_form: %i(account_id amount date memo payee subcategory_id)
    )
  end

  # Return the stored return location, clearing it from the session.
  #
  # @return [String] The URL to redirect to after a successful update.
  def return_location
    session.delete(:return_to) || budget_transactions_path(budget)
  end

  # Store the referer in the session.
  #
  # @return [void]
  def store_return_location
    session[:return_to] = request.referer
  end

  # Return the subcategory for the given `subcategory_id` parameter.
  #
  # @return [Category] The requested subcategory.
  # @return [nil] When no subcategory is provided.
  def subcategory
    @subcategory ||= budget.subcategories.find(parameters[:subcategory_id])
  end

  # Return the transaction for the given `id` parameter.
  #
  # @return [Transaction] The requested transaction.
  def transaction
    @transaction ||= budget.transactions.find(params[:id])
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
