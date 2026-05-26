# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate,
                     :current_budget

  before_action :redirect_authenticated_user,
                except: :destroy,
                if:     :signed_in?

  rate_limit to: 1, within: 1.second,   only: :create, name: "ip-address"
  rate_limit to: 5, within: 30.seconds, only: :create, name: "email", by: :normalized_email

  # Render the new session form.
  def new
    @form = SessionForm.new
  end

  # Create a new session from form parameters.
  def create
    @form = SessionForm.new(**form_parameters)

    if @form.valid?
      start_new_session_for(@form.user)

      redirect_to root_url, status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  # Terminate the current session and redirect to the sign-in page.
  def destroy
    terminate_session

    redirect_to new_session_url, status: :see_other
  end

  protected

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    params.expect(session_form: %i(email password)).to_h.symbolize_keys
  end

  # Return the e-mail from the form parameters, normalized for rate limit
  # bucketing so casing and whitespace variants share one bucket.
  #
  # @return [String] The normalized e-mail, or "blank" when none was provided.
  def normalized_email
    User.normalize_value_for(:email, form_parameters[:email].presence || "blank")
  end

  # Redirect a signed-in user away from the session form.
  #
  # @return [void]
  def redirect_authenticated_user
    redirect_to root_url, status: :see_other
  end
end
