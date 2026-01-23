# frozen_string_literal: true

class BudgetsController < ApplicationController
  # Render the budget.
  def index
    redirect_to budget_path(Budget.first!)
  end

  # Render a budget.
  def show
    @budget = Budget.includes(categories: :subcategories).find(params[:id])
  end
end
