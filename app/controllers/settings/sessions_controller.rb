# frozen_string_literal: true

module Settings
  class SessionsController < BaseController
    # Render the current user's active sessions.
    def index
      @sessions = Current.user.sessions.order(created_at: :desc)
    end

    # Revoke another session of the current user.
    #
    # @raise [ActiveRecord::RecordNotFound] When the session is not revocable.
    def destroy
      Current.user.sessions
             .where.not(id: Current.session.id)
             .destroy(params.expect(:id))

      redirect_to account_sessions_path, notice: t(".success"), status: :see_other
    end
  end
end
