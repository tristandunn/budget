# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import
  # maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :assign_current_budget

  private

  # Assign the resolved budget as the current budget.
  #
  # @return [void]
  def assign_current_budget
    Current.budget = current_budget
  end

  # Return the budget for the current request, resolved from route params.
  #
  # @return [Budget] The budget for the request.
  def current_budget
    @current_budget ||= Budget.find(params[:budget_id])
  end
end
