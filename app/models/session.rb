# frozen_string_literal: true

class Session < ApplicationRecord
  belongs_to :user

  has_secure_token :token

  # Destroy every other session belonging to the same user.
  #
  # @return [void]
  def revoke_others
    user.sessions.where.not(id: id).destroy_all
  end
end
