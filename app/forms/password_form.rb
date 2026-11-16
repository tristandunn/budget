# frozen_string_literal: true

class PasswordForm < BaseForm
  attr_accessor :current_password, :password, :password_confirmation, :user

  validates :current_password, presence: true
  validates :password,         presence:     true,
                               length:       { minimum: User::MINIMUM_PASSWORD_LENGTH, allow_blank: true },
                               confirmation: { allow_blank: true }
  validates :password_confirmation, presence: true

  validate :validate_current_password
  validate :validate_password_length

  # Update the user's password when the form is valid.
  #
  # @return [Boolean] Whether the password was changed.
  def save
    if valid?
      user.update(password: password, password_confirmation: password_confirmation)
    end
  end

  private

  # Ensure the current password matches the user's password.
  #
  # @return [void]
  def validate_current_password
    unless user.authenticate(current_password)
      errors.add(:current_password, :incorrect)
    end
  end

  # Ensure the new password is not longer than the maximum length.
  #
  # @return [void]
  def validate_password_length
    if password.to_s.bytesize > User::MAXIMUM_PASSWORD_LENGTH
      errors.add(:password, :too_long, count: User::MAXIMUM_PASSWORD_LENGTH)
    end
  end
end
