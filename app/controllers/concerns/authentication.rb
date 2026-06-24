# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :signed_in?,
                  :signed_out?
  end

  # Deny access by redirecting to the sign-in page.
  #
  # Uses a 303 See Other status so non-GET requests, such as Turbo Stream form
  # submissions whose session expired, are followed with a GET instead of
  # repeating the method.
  #
  # @return [void]
  def access_denied
    redirect_to new_session_url, status: :see_other
  end

  # Resume the user session, otherwise deny access.
  #
  # @return [void]
  def authenticate
    resume_session || access_denied
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

  # Set the current user and persist their ID to a fresh session.
  #
  # @param user [User] The user to start the session for.
  # @return [void]
  def start_new_session_for(user)
    Current.user = user

    reset_session

    session[:user_id] = user.id
  end

  # Clear the current user and reset the session.
  #
  # @return [void]
  def terminate_session
    Current.user = nil

    reset_session
  end

  # Attempt to find a user from the user ID in the session.
  #
  # Also remove the user ID from the session when no matching user exists.
  #
  # @return [User] The user when one was found for the session's user ID.
  # @return [nil] When no user ID is in the session or no user matches it.
  def user_from_session
    if session[:user_id].present?
      User.find_by(id: session[:user_id]).tap do |user|
        if user.nil?
          session.delete(:user_id)
        end
      end
    end
  end
end
