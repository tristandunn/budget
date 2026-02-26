# frozen_string_literal: true

class AssignmentsController < ApplicationController
  # Render the inline assignment edit form.
  def edit
    @budget               = budget
    @subcategory          = subcategory
    @subcategory_snapshot = subcategory_snapshot
    @form                 = AssignmentForm.new(budget: budget, subcategory: subcategory, date: date)
  end

  # Update the assignment for the subcategory.
  def update
    @budget               = budget
    @subcategory          = subcategory
    @subcategory_snapshot = subcategory_snapshot
    @form                 = AssignmentForm.new(assignment_parameters)

    if @form.save
      redirect_to budget_path(budget)
    else
      render :edit, status: :unprocessable_content
    end
  end

  protected

  # Return the budget for the given budget_id parameter.
  #
  # @return [Budget]
  def budget
    @budget ||= Budget.find(params[:budget_id])
  end

  # Return the current month date.
  #
  # @return [Date]
  def date
    Date.current.beginning_of_month
  end

  # Return the permitted form parameters.
  #
  # @return [ActionController::Parameters]
  def parameters
    @parameters ||= params.expect(assignment_form: %i(amount))
  end

  # Return the subcategory for the given category_id parameter.
  #
  # @return [Category]
  def subcategory
    @subcategory ||= budget.subcategories.find(params[:category_id])
  end

  # Return the current category snapshot for the subcategory.
  #
  # @return [CategorySnapshot]
  def subcategory_snapshot
    @subcategory_snapshot ||= subcategory.snapshots.find_or_initialize_by(budget: budget, date: date)
  end

  # Return the parameters for building the form.
  #
  # @return [Hash]
  def assignment_parameters
    {
      amount:      parameters[:amount],
      budget:      budget,
      date:        date,
      subcategory: subcategory
    }
  end
end
