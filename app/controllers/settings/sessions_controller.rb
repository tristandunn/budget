# frozen_string_literal: true

module Settings
  class SessionsController < BaseController
    # Render the current user's active sessions.
    def index
      @sessions = Current.user.sessions.order(created_at: :desc)
    end

    # Revoke another session of the current user, or every other session when
    # no ID is given.
    #
    # @raise [ActiveRecord::RecordNotFound] When the session is not revocable.
    def destroy
      if params[:id]
        destroy_one
      else
        destroy_others
      end

      redirect_to account_sessions_path, status: :see_other
    end

    private

    # Revoke the session with the given ID, which cannot be the current one.
    #
    # @return [void]
    # @raise [ActiveRecord::RecordNotFound] When the session is not revocable.
    def destroy_one
      Current.user.sessions
             .where.not(id: Current.session.id)
             .destroy(params.expect(:id))

      flash[:notice] = t("settings.sessions.destroy.success")
    end

    # Revoke every session of the current user except the current one.
    #
    # @return [void]
    def destroy_others
      Current.session.revoke_others

      flash[:notice] = t("settings.sessions.destroy.success_others")
    end
  end
end
