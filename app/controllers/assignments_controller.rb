# frozen_string_literal: true

class AssignmentsController < ApplicationController
  # Render the inline assignment edit form.
  def edit
    @budget               = current_budget
    @subcategory          = subcategory
    @subcategory_snapshot = subcategory_snapshot
    @form                 = AssignmentForm.new(budget: current_budget, subcategory: subcategory, date: date)
  end

  # Update the assignment for the subcategory.
  def update
    @budget               = current_budget
    @subcategory          = subcategory
    @subcategory_snapshot = subcategory_snapshot
    @form                 = AssignmentForm.new(assignment_parameters)

    if @form.save
      redirect_to month_budget_path(current_budget, month: date.month, year: date.year)
    else
      render :edit, status: :unprocessable_content
    end
  end

  protected

  # Return the parameters for building the form.
  #
  # @return [Hash] The permitted parameters merged with the budget, date, and subcategory.
  def assignment_parameters
    {
      amount:      parameters[:amount],
      budget:      current_budget,
      date:        date,
      subcategory: subcategory
    }
  end

  # Parse the year and month parameters, falling back to the current month.
  #
  # @return [Date] The parsed date, or the current month if parsing fails.
  def date
    @date ||= Date.new(params.expect(:year).to_i, params.expect(:month).to_i)
  rescue ActionController::ParameterMissing, Date::Error
    @date = Date.current.beginning_of_month
  end

  # Return the permitted form parameters.
  #
  # @return [ActionController::Parameters] The permitted parameters for the form.
  def parameters
    @parameters ||= params.expect(assignment_form: %i(amount))
  end

  # Return the subcategory for the given category_id parameter.
  #
  # @return [Category] The requested subcategory.
  def subcategory
    @subcategory ||= current_budget.subcategories.find(params.expect(:category_id))
  end

  # Return the current category snapshot for the subcategory.
  #
  # @return [CategorySnapshot] The snapshot for the current month.
  def subcategory_snapshot
    @subcategory_snapshot ||= subcategory.snapshots.find_or_initialize_by(budget: current_budget, date: date)
  end
end
