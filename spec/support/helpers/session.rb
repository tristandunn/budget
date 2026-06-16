# frozen_string_literal: true

module RSpec
  module Helpers
    module Session
      module Shared
        def sign_in
          sign_in_as create(:user)
        end

        def sign_in_for(budget)
          sign_in_as(budget.users.order(:id).first)
        end
      end

      module Controller
        include Shared

        def sign_in_as(user)
          session[:user_id] = user.id
        end
      end

      module Feature
        include Shared

        def sign_in_as(user)
          visit "#{Middleware::Backdoor::SIGN_IN_PATH}?user=#{user.id}"
        end

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
