# frozen_string_literal: true

class BudgetsController < ApplicationController
  skip_before_action :load_budget, only: :index

  before_action :redirect_to_canonical_month, only: :show, if: :out_of_range_month?

  # Redirect to the last viewed budget, falling back to the first budget.
  def index
    scope = Current.user.budgets

    redirect_to(
      if session[:budget_id].present?
        scope.find(session[:budget_id])
      else
        scope.first!
      end
    )
  end

  # Render a budget.
  def show
    @budget          = Current.budget
    @budget_snapshot = current_budget_snapshot
  end

  # Render the budget settings form.
  def edit
    @budget = Current.budget
  end

  # Update the budget from form parameters.
  def update
    @budget = Current.budget

    if @budget.update(budget_parameters)
      unless request.format.turbo_stream?
        redirect_to budget_path(@budget), status: :see_other
      end
    else
      render :edit, status: :unprocessable_content, formats: [:html]
    end
  end

  # Render the list of budgets the user can switch to.
  def switch
    @budget  = Current.budget
    @budgets = Current.user.budgets.order(:name)
  end

  private

  delegate :date, to: :current_budget_snapshot, prefix: :snapshot

  # Return the permitted budget parameters.
  #
  # @return [ActionController::Parameters] The permitted parameters.
  def budget_parameters
    params.expect(budget: %i(name time_zone))
  end

  # Return the budget snapshot for the current request.
  #
  # @return [BudgetSnapshot] The current budget snapshot.
  def current_budget_snapshot
    @current_budget_snapshot ||= BudgetSnapshot.new(Current.budget, date: date)
  end

  # Return the date for the `year` and `month` parameters.
  #
  # @return [Date] The first day of the requested month.
  # @return [nil] When the parameters are missing or do not form a month.
  def date
    @date ||= BudgetSnapshotDate.parse(params[:year], params[:month])
  end

  # Find the budget for the current request, resolved from the `id` parameter.
  #
  # @return [Budget] The budget for the request.
  def find_budget
    Current.user.budgets.includes(:accounts, categories: :subcategories).find(params.expect(:id))
  end

  # Return whether the request supplied a year and month that did not
  # resolve to the displayed snapshot date.
  #
  # @return [Boolean] Whether the requested month is out of the snapshot range.
  # @return [nil] When no year parameter was supplied.
  def out_of_range_month?
    if params[:year].present?
      [params[:year].to_i, params[:month].to_i] != [snapshot_date.year, snapshot_date.month]
    end
  end

  # Redirect to the canonical URL for the resolved snapshot date.
  #
  # @return [void]
  def redirect_to_canonical_month
    redirect_to month_budget_path(Current.budget, month: snapshot_date.month, year: snapshot_date.year)
  end
end
