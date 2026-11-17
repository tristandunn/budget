# frozen_string_literal: true

module Middleware
  class Backdoor
    SIGN_IN_PATH = "/session/new"

    # Initialize the middleware.
    #
    # @param app [#call] The Rack application.
    def initialize(app)
      @app = app
    end

    # Translate the `user` parameter into a database session and cookie.
    #
    # Only a scalar value is translated, so a nested `user` parameter submitted
    # by a form is ignored.
    #
    # On the sign-in path, return a no-content response so the feature test
    # sign-in helper can set the session cookie without rendering anything or
    # following the redirect `SessionsController` would issue for an
    # already-authenticated request. This keeps test sign-in a pure side
    # effect, so the next `visit` in the test is the intended destination.
    #
    # For other paths, strip the parameter from the query string and continue
    # to the underlying application so the request is served as it would be
    # in production.
    #
    # @param env [Hash] The request environment.
    # @return [Array] The Rack response.
    def call(env)
      request = ActionDispatch::Request.new(env)

      if request.params["user"].is_a?(String)
        sign_in(request, request.params["user"].to_i)

        if request.path == SIGN_IN_PATH
          return [204, {}, []]
        end

        query_hash = Rack::Utils.parse_query(env["QUERY_STRING"])
        query_hash.delete("user")
        env["QUERY_STRING"] = Rack::Utils.build_query(query_hash)
      end

      @app.call(env)
    end

    private

    # Create a session for the user and store its token in a signed cookie.
    #
    # @param request [ActionDispatch::Request] The current request.
    # @param user_id [Integer] The ID of the user to sign in.
    # @return [void]
    def sign_in(request, user_id)
      Session.create!(user_id: user_id).tap do |session|
        request.cookie_jar.signed.permanent[:session_token] = session.token
      end
    end
  end
end
