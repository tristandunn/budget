# frozen_string_literal: true

class CategoriesController < ApplicationController
  # Render the transactions that make up the category activity for the month.
  def activity
    @category        = category
    @budget_snapshot = budget_snapshot
    @transactions    = current_budget.transactions
                                     .where(subcategory: category, date: budget_snapshot.date.all_month)
                                     .where.not(status: :upcoming)
                                     .includes(:payee)
                                     .reorder(date: :desc, created_at: :desc)
  end

  # Render the category details.
  def show
    @budget          = current_budget
    @budget_snapshot = budget_snapshot
    @category        = category
  end

  # Render the summary for the selected subcategories.
  def summary
    @budget_snapshot = budget_snapshot
    @summary         = CategorySummary.new(
      current_budget,
      budget_snapshot: @budget_snapshot,
      ids:             params.expect(ids: [])
    )
  end

  # Render the category edit form.
  def edit
    @budget   = current_budget
    @category = category
    @form     = CategoryForm.from(category: category)
  end

  # Update the category.
  def update
    @budget   = current_budget
    @category = category
    @form     = CategoryForm.new(category: category, **form_parameters)

    if @form.update
      @budget_snapshot = budget_snapshot

      unless request.format.turbo_stream?
        redirect_to budget_path(current_budget), status: :see_other
      end
    else
      render :edit, status: :unprocessable_content, formats: [:html]
    end
  end

  private

  # Return the budget snapshot for the displayed month.
  #
  # @return [BudgetSnapshot] The current budget snapshot.
  def budget_snapshot
    @budget_snapshot ||= BudgetSnapshot.new(current_budget, date: date)
  end

  # Return the category for the given `id` parameter.
  #
  # Inflow categories are marked as not found to prevent viewing and renaming.
  #
  # @return [Category] The requested category.
  # @raise [ActiveRecord::RecordNotFound] When the category is an inflow category.
  def category
    @category ||= current_budget.subcategories.find(params.expect(:id)).tap do |record|
      if record.inflow?
        raise ActiveRecord::RecordNotFound
      end
    end
  end

  # Return the date for the `year` and `month` parameters.
  #
  # @return [Date] The first day of the requested month.
  # @return [nil] When the parameters are missing or do not form a month.
  def date
    @date ||= BudgetSnapshotDate.parse(params[:year], params[:month])
  end

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    params.expect(category_form: %i(name)).to_h.symbolize_keys
  end
end
