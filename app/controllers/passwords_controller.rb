# frozen_string_literal: true

class PasswordsController < ApplicationController
  layout "user"

  skip_before_action :current_budget

  # Render the change password form.
  def show
    @form = PasswordForm.new(user: Current.user)
  end

  # Change the current user's password from form parameters.
  def update
    @form = PasswordForm.new(user: Current.user, **form_parameters)

    if @form.save
      redirect_to account_password_path, notice: t(".success"), status: :see_other
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    params.expect(password_form: %i(current_password password password_confirmation))
          .to_h
          .symbolize_keys
  end
end
