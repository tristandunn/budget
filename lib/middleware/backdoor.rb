# frozen_string_literal: true

module Middleware
  class Backdoor
    SIGN_IN_PATH = "/session/new"

    # Initialize the middleware.
    #
    # @param app [Class] The Rack application.
    # @return [void]
    def initialize(app)
      @app = app
    end

    # Translate the `user` parameter into a session.
    #
    # On the sign-in path, return a no-content response so the feature test
    # sign-in helper can set the session cookie without rendering anything or
    # following the redirect SessionsController would issue for an
    # already-authenticated request. This keeps test sign-in a pure side-effect
    # and the next `visit` in the test is the intended destination.
    #
    # For other paths, strip the parameter from the query string and continue
    # to the underlying application so the request is served as it would be in
    # production.
    #
    # @param env [Hash] The request environment.
    # @return [Array] The Rack response.
    def call(env)
      request = Rack::Request.new(env)

      if request.params.key?("user")
        request.session[:user_id] = request.params["user"].to_i

        if request.path == SIGN_IN_PATH
          return [204, {}, []]
        end

        query_hash = Rack::Utils.parse_query(env["QUERY_STRING"])
        query_hash.delete("user")
        env["QUERY_STRING"] = Rack::Utils.build_query(query_hash)
      end

      @app.call(env)
    end
  end
end
