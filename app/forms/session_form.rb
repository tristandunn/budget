# frozen_string_literal: true

class SessionForm < BaseForm
  attr_accessor :email, :password

  validates :email,    presence: true
  validates :password, presence: true

  validate :validate_credentials

  # Attempt to find the session user by e-mail and password.
  #
  # @return [User] The user when the credentials match.
  # @return [nil] When no user matches the credentials.
  def user
    if defined?(@user)
      @user
    else
      @user = User.authenticate_by(email: email, password: password)
    end
  end

  private

  # Ensure a user was found and the password matches.
  #
  # @return [void]
  def validate_credentials
    if user.nil?
      errors.add(:email, :unknown)
    end
  end
end
