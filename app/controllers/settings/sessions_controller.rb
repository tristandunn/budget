# frozen_string_literal: true

module Settings
  class SessionsController < BaseController
    # Render the current user's active sessions.
    def index
      @sessions = Current.user.sessions.order(created_at: :desc)
    end
  end
end
