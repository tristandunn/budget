# frozen_string_literal: true

class CategoriesController < ApplicationController
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

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    params.expect(category_form: %i(name)).to_h.symbolize_keys
  end
end
