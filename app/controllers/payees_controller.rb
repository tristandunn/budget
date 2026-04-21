# frozen_string_literal: true

class PayeesController < ApplicationController
  # Render payee names ordered alphabetically.
  def index
    render json: budget.payees.order(:name).pluck(:name)
  end

  private

  # Return the budget for the given `budget_id` parameter.
  #
  # @return [Budget] The requested budget.
  def budget
    @budget ||= Budget.find(params[:budget_id])
  end
end
