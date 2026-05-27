# frozen_string_literal: true

class BudgetsController < ApplicationController
  before_action :redirect_to_canonical_month, only: :show, if: :out_of_range_month?

  # Render the budget.
  def index
    redirect_to budget_path(current_budget)
  end

  # Render a budget.
  def show
    @budget          = current_budget
    @budget_snapshot = current_budget_snapshot
  end

  private

  delegate :date, to: :current_budget_snapshot, prefix: :snapshot

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

  # Return the budget snapshot for the current request.
  #
  # @return [BudgetSnapshot] The current budget snapshot.
  def current_budget_snapshot
    @current_budget_snapshot ||= BudgetSnapshot.new(current_budget, month: params[:month], year: params[:year])
  end

  # Return whether or not the request supplied a year and month that did not
  # resolve to the displayed snapshot date.
  #
  # @return [Boolean] Whether the requested month is out of the snapshot range.
  def out_of_range_month?
    if params[:year].present?
      [params[:year].to_i, params[:month].to_i] != [snapshot_date.year, snapshot_date.month]
    end
  end

  # Redirect to the canonical URL for the resolved snapshot date.
  #
  # @return [void]
  def redirect_to_canonical_month
    redirect_to month_budget_path(current_budget, month: snapshot_date.month, year: snapshot_date.year)
  end
end
