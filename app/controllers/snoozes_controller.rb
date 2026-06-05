# frozen_string_literal: true

class SnoozesController < ApplicationController
  # Snooze the monthly spending target for the displayed month.
  def create
    @budget          = current_budget
    @category        = category
    @budget_snapshot = budget_snapshot

    category_snapshot.update!(metadata: category_snapshot.metadata.merge("snoozed" => true))

    respond_to do |format|
      format.html do
        redirect_to displayed_budget_path
      end
      format.turbo_stream
    end
  end

  # Unsnooze the monthly spending target for the displayed month.
  def destroy
    @budget          = current_budget
    @category        = category
    @budget_snapshot = budget_snapshot

    category_snapshot.update!(metadata: category_snapshot.metadata.except("snoozed"))

    respond_to do |format|
      format.html do
        redirect_to displayed_budget_path
      end
      format.turbo_stream
    end
  end

  protected

  # Return the budget snapshot for the displayed month.
  #
  # @return [BudgetSnapshot] The current budget snapshot.
  def budget_snapshot
    @budget_snapshot ||= BudgetSnapshot.new(current_budget, month: params[:month], year: params[:year])
  end

  # Return the category for the given category_id parameter, scoped to
  # subcategories with a monthly target.
  #
  # @return [Category] The requested category.
  def category
    @category ||= current_budget.subcategories
                                .with_monthly_target
                                .find(params.expect(:category_id))
  end

  # Return the category snapshot for the displayed month, initializing one if needed.
  #
  # @return [CategorySnapshot] The category snapshot for the displayed month.
  def category_snapshot
    @category_snapshot ||= category.snapshots.find_or_initialize_by(
      budget: current_budget,
      date:   budget_snapshot.date
    )
  end

  # Return the budget path for the displayed month.
  #
  # @return [String] The path to the budget for the displayed month.
  def displayed_budget_path
    month_budget_path(current_budget, year: params[:year], month: params[:month])
  end
end
