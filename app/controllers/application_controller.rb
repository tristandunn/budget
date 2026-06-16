# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import
  # maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate
  before_action :set_request_variant
  before_action :current_budget

  private

  # Return the budget for the current request, resolved from route params.
  #
  # @return [Budget] The budget for the request.
  def current_budget
    Current.budget ||= if request.variant.mobile?
                         Current.user.budgets.find(params.expect(:budget_id))
                       else
                         Current.user.budgets.includes(:accounts).find(params.expect(:budget_id))
                       end
  end

  # Select the request variant as either desktop or mobile.
  #
  # @return [void]
  def set_request_variant
    request.variant = if browser.device.mobile?
                        :mobile
                      else
                        :desktop
                      end
  end
end
