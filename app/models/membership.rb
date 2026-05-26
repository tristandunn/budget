# frozen_string_literal: true

class Membership < ApplicationRecord
  belongs_to :budget, inverse_of: :memberships
  belongs_to :user,   inverse_of: :memberships

  validates :user_id, uniqueness: { scope: :budget_id }
end
