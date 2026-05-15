# frozen_string_literal: true

class User < ApplicationRecord
  EMAIL_MATCHER           = /\A[^@\s]+@(?:[-a-z0-9]+\.)+[a-z]{2,}\z/
  MAXIMUM_EMAIL_LENGTH    = 255
  MINIMUM_PASSWORD_LENGTH = 8

  has_secure_password

  normalizes :email, with: ->(value) { value.strip.downcase }

  validates :email, presence:   true,
                    length:     { maximum: MAXIMUM_EMAIL_LENGTH },
                    format:     { with: EMAIL_MATCHER },
                    uniqueness: { case_sensitive: false }

  validates :password, length: { minimum: MINIMUM_PASSWORD_LENGTH, allow_blank: true }
end
