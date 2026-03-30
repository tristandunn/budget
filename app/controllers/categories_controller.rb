# frozen_string_literal: true

class CategoriesController < ApplicationController
  # Render the category edit form.
  def edit
    @budget   = budget
    @category = category
  end

  # Update the category.
  def update
    @budget   = budget
    @category = category

    if @category.update(category_parameters)
      redirect_to budget_path(budget)
    else
      render :edit, status: :unprocessable_content
    end
  end

  protected

  # Return the budget for the given budget_id parameter.
  #
  # @return [Budget] The requested budget.
  def budget
    @budget ||= Budget.find(params[:budget_id])
  end

  # Return the category for the given id parameter.
  #
  # @return [Category] The requested category.
  def category
    @category ||= budget.subcategories.find(params[:id])
  end

  # Return the permitted category parameters.
  #
  # @return [ActionController::Parameters] The permitted parameters.
  def category_parameters
    params.expect(category: %i(name))
  end
end
