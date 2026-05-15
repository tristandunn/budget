# frozen_string_literal: true

module RSpec
  module Helpers
    module Session
      module Controller
        def sign_in
          sign_in_as create(:user)
        end

        def sign_in_as(user)
          session[:user_id] = user.id
        end
      end

      module Feature
        def sign_in
          sign_in_as create(:user)
        end

        def sign_in_as(user)
          visit root_path(user: user.id)
        end

        def sign_out
          find("button[aria-label='#{t("budgets.show.menu")}']").click
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
