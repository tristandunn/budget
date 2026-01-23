# frozen_string_literal: true

class BudgetsController < ApplicationController
  # Render the budget.
  def index
    redirect_to budget_path(Budget.first!)
  end

  # Render a budget.
  def show
    @date      = Date.current.beginning_of_month
    @budget    = Budget.includes(categories: :subcategories).find(params[:id])
    @snapshots = @budget.category_snapshots.for_month(@date).index_by(&:category_id)
  end
end
