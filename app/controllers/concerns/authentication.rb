# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  SESSION_COOKIE = :session_token

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

  # Attempt to set the current session and user from the token cookie.
  #
  # @return [Session] The session when one matches the token cookie.
  # @return [nil] When there is no token cookie or no session matches it.
  def resume_session
    Current.session ||= session_from_cookie
  end

  # Return whether a user is signed in.
  #
  # @return [Boolean] Whether a user is signed in.
  def signed_in?
    resume_session.present?
  end

  # Return whether a user is not signed in.
  #
  # @return [Boolean] Whether a user is not signed in.
  def signed_out?
    !signed_in?
  end

  # Set the current session and start a new database-backed session for them.
  #
  # @param user [User] The user to start the session for.
  # @return [void]
  def start_new_session_for(user)
    reset_session

    user.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent&.first(1024)
    ).tap do |record|
      Current.session = record

      cookies.signed.permanent[SESSION_COOKIE] = {
        value:     record.token,
        httponly:  true,
        same_site: :lax
      }
    end
  end

  # Destroy the current database session, clear it from the current attributes,
  # and reset the cookie session.
  #
  # @return [void]
  def terminate_session
    resume_session&.destroy

    Current.session = nil

    cookies.delete(SESSION_COOKIE)

    reset_session
  end

  private

  # Find the session record for the token cookie.
  #
  # @return [Session] The session when one matches the token.
  # @return [nil] When there is no token or no session matches it.
  def session_from_cookie
    token = cookies.signed[SESSION_COOKIE]

    if token.present?
      Session.includes(:user).find_by(token: token)
    end
  end
end
