# frozen_string_literal: true

class TransactionsController < ApplicationController
  # Render the new transaction form.
  def new
    @form          = TransactionForm.new(budget: budget)
    @subcategories = budget.subcategories
  end

  # Create a new transaction.
  def create
    @form          = TransactionForm.new(transaction_parameters)
    @subcategories = budget.subcategories

    if @form.save
      redirect_to budget_path(budget)
    else
      render :new
    end
  end

  protected

  # Return the budget for the given `budget_id` parameter.
  #
  # @return [Budget] The requested budget.
  def budget
    @budget ||= Budget.find(params[:budget_id])
  end

  # Return the category for the given `subcategory_id` parameter.
  #
  # @return [Category] The requested subcategory.
  # @return [nil] When no subcategory is provided.
  def category
    if parameters[:subcategory_id].present?
      @category ||= budget.subcategories.find(parameters[:subcategory_id])
    end
  end

  # Return the permitted form parameters.
  #
  # @return [ActionController::Parameters]
  def parameters
    @parameters ||= params.expect(transaction_form: %i(amount subcategory_id))
  end

  # Return the permitted parameters with budget and category.
  #
  # @return [Hash]
  def transaction_parameters
    { amount: parameters[:amount], budget: budget, category: category }
  end
end
