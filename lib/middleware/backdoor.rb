# frozen_string_literal: true

module Middleware
  class Backdoor
    # Initialize the middleware.
    #
    # @param app [Class] The Rack application.
    # @return [void]
    def initialize(app)
      @app = app
    end

    # Update the session with user ID and remove them from the parameters,
    # when present.
    #
    # @param env [Hash] The request environment.
    # @return [void]
    def call(env)
      request = Rack::Request.new(env)

      if request.params.key?("user")
        request.session[:user_id] = request.params["user"].to_i

        query_hash = Rack::Utils.parse_query(env["QUERY_STRING"])
        query_hash.delete("user")
        env["QUERY_STRING"] = Rack::Utils.build_query(query_hash)
      end

      @app.call(env)
    end
  end
end
