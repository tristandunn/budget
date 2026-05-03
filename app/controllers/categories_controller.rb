# frozen_string_literal: true

class CategoriesController < ApplicationController
  # Render the category details.
  def show
    @budget                   = budget
    @category                 = category
    @budget_snapshot          = budget_snapshot
    @previous_budget_snapshot = previous_budget_snapshot
  end

  # Render the category edit form.
  def edit
    @budget   = budget
    @category = category
    @form     = CategoryForm.from(category: category)
  end

  # Update the category.
  def update
    @budget   = budget
    @category = category
    @form     = CategoryForm.new(category: category, **form_parameters)

    if @form.update
      @budget_snapshot          = budget_snapshot
      @previous_budget_snapshot = previous_budget_snapshot

      unless request.format.turbo_stream?
        redirect_to budget_path(budget)
      end
    else
      render :edit, status: :unprocessable_content, formats: [:html]
    end
  end

  protected

  # Return the budget for the given budget_id parameter.
  #
  # @return [Budget] The requested budget.
  def budget
    @budget ||= Budget.find(params[:budget_id])
  end

  # Return the budget snapshot for the displayed month.
  #
  # @return [BudgetSnapshot] The current budget snapshot.
  def budget_snapshot
    @budget_snapshot ||= BudgetSnapshot.new(budget, month: params[:month], year: params[:year])
  end

  # Return the category for the given id parameter.
  #
  # @return [Category] The requested category.
  def category
    @category ||= budget.subcategories.find(params[:id])
  end

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    params.expect(category_form: %i(name)).to_h.symbolize_keys
  end

  # Return the budget snapshot for the month preceding the displayed month.
  #
  # @return [BudgetSnapshot, nil] The previous budget snapshot, or nil on the first month.
  def previous_budget_snapshot
    unless budget_snapshot.first_month?
      @previous_budget_snapshot ||= BudgetSnapshot.new(
        budget,
        month: budget_snapshot.previous_date.month,
        year:  budget_snapshot.previous_date.year
      )
    end
  end
end
