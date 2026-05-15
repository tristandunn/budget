# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :signed_in?,
                  :signed_out?
  end

  # Attempt to set the current user from the session.
  #
  # @return [User] The user when one was found in the session.
  # @return [nil] When no user ID is in the session or the user cannot be found.
  def resume_session
    Current.user ||= user_from_session
  end

  # Determine if a user is signed in.
  #
  # @return [Boolean]
  def signed_in?
    resume_session.present?
  end

  # Determine if a user is not signed in.
  #
  # @return [Boolean]
  def signed_out?
    !signed_in?
  end

  # Set the current user and persist their ID to the session.
  #
  # @param user [User] The user to start the session for.
  # @return [void]
  def start_new_session_for(user)
    Current.user = user

    session[:user_id] = user.id
  end

  # Clear the current user and remove the user ID from the session.
  #
  # @return [void]
  def terminate_session
    Current.user = nil

    session.delete(:user_id)
  end

  # Attempt to find a user from the user ID in the session.
  #
  # @return [User] The user when one was found for the session's user ID.
  # @return [nil] When no user ID is in the session or no user matches it.
  def user_from_session
    if session[:user_id].present?
      User.find_by(id: session[:user_id])
    end
  end
end
