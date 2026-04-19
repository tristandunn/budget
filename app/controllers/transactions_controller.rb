# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :store_return_location, only: %i(new edit)
  before_action :require_unreconciled, only: %i(edit update destroy clear unclear)

  # Render all transactions grouped by date.
  def index
    @budget = budget
    @scheduled_transactions, @current_transactions = filtered_transactions
  end

  # Render the new transaction form.
  def new
    @accounts = budget.accounts
    @form     = TransactionForm.new(account: default_account, budget: budget)
  end

  # Render the edit transaction form.
  def edit
    @accounts    = budget.accounts
    @transaction = transaction
    @form        = TransactionForm.from(transaction: transaction)
  end

  # Create a new transaction.
  def create
    @accounts = budget.accounts
    @form     = TransactionForm.new(transaction_parameters)

    if @form.save
      redirect_to return_location, status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  # Update an existing transaction.
  def update
    @accounts    = budget.accounts
    @transaction = transaction
    @form        = TransactionForm.new(transaction_parameters)

    if @form.update(transaction)
      redirect_to return_location, status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Destroy an existing transaction.
  def destroy
    DestroyTransaction.call(transaction: transaction)

    redirect_to return_location, status: :see_other
  end

  # Mark a transaction as cleared.
  def clear
    @transaction = transaction
    @transaction.update!(status: :cleared)

    respond_to do |format|
      format.turbo_stream { render "transactions/clear" }
    end
  end

  # Mark a transaction as pending.
  def unclear
    @transaction = transaction
    @transaction.update!(status: :pending)

    respond_to do |format|
      format.turbo_stream { render "transactions/clear" }
    end
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

  # Return the default account from the query parameter, if present.
  #
  # @return [Account] The requested account.
  # @return [nil] When no account is provided.
  def default_account
    if params[:account_id].present?
      budget.accounts.find(params[:account_id])
    end
  end

  # Return transactions for the budget, grouped by upcoming or not, optionally
  # excluding reconciled transactions.
  #
  # @return [Array(Array<Transaction>, Array<Transaction>)] The upcoming and current transactions.
  def filtered_transactions
    transactions = budget.transactions.includes(:account, :payee, :subcategory)
    transactions = transactions.where.not(status: :reconciled) if budget.settings.hide_reconciled?
    transactions.partition(&:upcoming?)
  end

  # Return the permitted form parameters.
  #
  # @return [ActionController::Parameters] The permitted parameters for the form.
  def parameters
    @parameters ||= params.expect(
      transaction_form: %i(account_id amount date frequency memo payee subcategory_id)
    )
  end

  # Redirect if the transaction is reconciled.
  #
  # @return [void]
  def require_unreconciled
    if transaction.reconciled?
      redirect_to return_location, status: :see_other
    end
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
    @transaction ||= budget.transactions.includes(:payee).find(params[:id])
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
      frequency:   parameters[:frequency],
      memo:        parameters[:memo],
      payee:       parameters[:payee],
      subcategory: subcategory
    }
  end
end
