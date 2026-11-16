# frozen_string_literal: true

module Settings
  class AccountsController < BaseController
    # Render the user settings.
    def show
      @user = Current.user
    end

    # Update the current user from form parameters.
    def update
      @user = Current.user

      if @user.update(user_parameters)
        redirect_to account_path, notice: t(".success"), status: :see_other
      else
        render :show, status: :unprocessable_content, formats: [:html]
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
end
