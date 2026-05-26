# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import
  # maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate
  before_action :current_budget

  private

  # Return the budget for the current request, resolved from route params.
  #
  # @return [Budget] The budget for the request.
  def current_budget
    Current.budget ||= Current.user.budgets.find(params.expect(:budget_id))
  end
end
