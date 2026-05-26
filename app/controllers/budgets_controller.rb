# frozen_string_literal: true

class BudgetsController < ApplicationController
  # Render the budget.
  def index
    redirect_to budget_path(current_budget)
  end

  # Render a budget.
  def show
    @budget          = current_budget
    @budget_snapshot = BudgetSnapshot.new(@budget, month: params[:month], year: params[:year])
  end

  private

  # Return the budget for the current request, or fall back to the
  # first budget.
  #
  # @return [Budget] The budget for the request.
  def current_budget
    Current.budget ||= if params[:id]
                         Current.user.budgets
                                .includes(categories: :subcategories)
                                .find(params.expect(:id))
                       else
                         Current.user.budgets.first!
                       end
  end
end
