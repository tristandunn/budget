# frozen_string_literal: true

class TransactionsController < ApplicationController
  # Render the new transaction form.
  def new
    @form = TransactionForm.new(budget: budget, category: category)
  end

  # Create a new transaction.
  def create
    @form = TransactionForm.new(transaction_parameters)

    if @form.save
      redirect_to budget_path(budget)
    else
      render :new
    end
  end

  protected

  # Return the budget for the given `budget_id` parameter.
  #
  # @return [Budget]
  def budget
    @budget ||= Budget.find(params[:budget_id])
  end

  # Return the category for the given `subcategory_id` parameter.
  #
  # @return [Category]
  def category
    @category ||= budget.subcategories.find(params[:subcategory_id])
  end

  # Return the permitted parameters from the required transaction form parameter.
  #
  # @return [ActionController::Parameters]
  def transaction_parameters
    params.expect(transaction_form: %i(amount)).merge(budget: budget, category: category)
  end
end
