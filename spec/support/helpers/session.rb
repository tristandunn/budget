# frozen_string_literal: true

module RSpec
  module Helpers
    module Session
      module Shared
        # Sign in as a newly created user.
        #
        # @return [void]
        def sign_in
          sign_in_as create(:user)
        end

        # Sign in as the first user of the given budget.
        #
        # @param budget [Budget] The budget to sign in a user for.
        # @return [void]
        def sign_in_for(budget)
          sign_in_as(budget.users.order(:id).first)
        end
      end

      module Controller
        include Shared

        # Sign in as the given user by setting the session identifier directly.
        #
        # @param user [User] The user to sign in as.
        # @return [void]
        def sign_in_as(user)
          session[:user_id] = user.id
        end
      end

      module Feature
        include Shared

        # Sign in as the given user by visiting the backdoor sign-in path.
        #
        # @param user [User] The user to sign in as.
        # @return [void]
        def sign_in_as(user)
          visit "#{Middleware::Backdoor::SIGN_IN_PATH}?user=#{user.id}"
        end

        # Sign out of the current session by clicking the sign-out button.
        #
        # @return [void]
        def sign_out
          click_button t("budgets.show.sign_out")
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Helpers::Session::Controller, type: :controller
  config.include RSpec::Helpers::Session::Feature,    type: :feature
end
