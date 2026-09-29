# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import
  # maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :block_bots
  before_action :authenticate
  before_action :set_request_variant
  before_action :current_budget

  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_authenticity_token

  private

  # Respond with not found for any bots.
  #
  # @return [void]
  def block_bots
    if browser.bot?
      head :not_found
    end
  end

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

  # Deny access when signed out, otherwise re-raise the error.
  #
  # The authenticity token check happens before authentication, so submitting a
  # form after the session has ended fails the check instead of redirecting to
  # the sign-in page.
  #
  # @param error [ActionController::InvalidAuthenticityToken] The error raised.
  # @return [void]
  # @raise [ActionController::InvalidAuthenticityToken] When a user is signed in.
  def invalid_authenticity_token(error)
    if signed_out?
      access_denied
    else
      raise error
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
