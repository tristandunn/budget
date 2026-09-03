# frozen_string_literal: true

class CategoriesController < ApplicationController
  # Render the category details.
  def show
    @budget                = current_budget
    @category              = category
    @budget_snapshot       = budget_snapshot
    @upcoming_transactions = UpcomingTransactions.new(
      budget_snapshot: @budget_snapshot,
      category:        @category
    )
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
        redirect_to budget_path(current_budget)
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
    @budget_snapshot ||= BudgetSnapshot.new(current_budget, month: params[:month], year: params[:year])
  end

  # Return the category for the given id parameter.
  #
  # Inflow categories are marked as not found to prevent viewing and renaming.
  #
  # @raise [ActiveRecord::RecordNotFound] If the category is an inflow category.
  # @return [Category] The requested category.
  def category
    @category ||= current_budget.subcategories.find(params.expect(:id)).tap do |record|
      if record.inflow?
        raise ActiveRecord::RecordNotFound
      end
    end
  end

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    params.expect(category_form: %i(name)).to_h.symbolize_keys
  end
end
