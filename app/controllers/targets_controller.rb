# frozen_string_literal: true

class TargetsController < ApplicationController
  # Render the target edit form.
  def edit
    @budget          = current_budget
    @budget_snapshot = budget_snapshot
    @category        = category
    @form            = TargetForm.from(category: category)
  end

  # Update the target on the category.
  def update
    @budget          = current_budget
    @budget_snapshot = budget_snapshot
    @category        = category
    @form            = TargetForm.new(category: category, **form_parameters)

    if @form.update
      @previous_budget_snapshot = previous_budget_snapshot

      respond_to do |format|
        format.html do
          redirect_to displayed_budget_path
        end
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_content, formats: [:html]
    end
  end

  # Clear the target on the category.
  def destroy
    @budget                   = current_budget
    @category                 = category
    @budget_snapshot          = budget_snapshot
    @previous_budget_snapshot = previous_budget_snapshot

    category.update!(target_type: nil, target_amount: nil)

    respond_to do |format|
      format.html do
        redirect_to displayed_budget_path
      end
      format.turbo_stream
    end
  end

  private

  # Return the budget snapshot for the displayed month.
  #
  # @return [BudgetSnapshot] The current budget snapshot.
  def budget_snapshot
    @budget_snapshot ||= BudgetSnapshot.new(current_budget, month: params[:month], year: params[:year])
  end

  # Return the category for the given category_id parameter.
  #
  # @return [Category] The requested category.
  def category
    @category ||= current_budget.subcategories.find(params.expect(:category_id))
  end

  # Return the budget path for the displayed month.
  #
  # @return [String] The path to the budget for the displayed month.
  def displayed_budget_path
    month_budget_path(current_budget, month: budget_snapshot.date.month, year: budget_snapshot.date.year)
  end

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    params.expect(target_form: %i(target_type target_amount_input)).to_h.symbolize_keys
  end

  # Return the budget snapshot for the month preceding the displayed month.
  #
  # @return [BudgetSnapshot, nil] The previous budget snapshot, or nil on the first month.
  def previous_budget_snapshot
    unless budget_snapshot.first_month?
      @previous_budget_snapshot ||= BudgetSnapshot.new(
        current_budget,
        month: budget_snapshot.previous_date.month,
        year:  budget_snapshot.previous_date.year
      )
    end
  end
end
