# frozen_string_literal: true

class UsersController < ApplicationController
  skip_before_action :current_budget

  # Render the user settings form.
  def edit
    @user = Current.user
  end

  # Update the current user from form parameters.
  def update
    @user = Current.user

    if @user.update(user_parameters)
      unless request.format.turbo_stream?
        redirect_back_or_to root_path, status: :see_other
      end
    else
      render :edit, status: :unprocessable_content, formats: [:html]
    end
  end

  private

  # Return the permitted user parameters.
  #
  # @return [ActionController::Parameters] The permitted parameters.
  def user_parameters
    params.expect(user: :email)
  end
end
