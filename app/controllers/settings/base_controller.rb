# frozen_string_literal: true

module Settings
  class BaseController < ApplicationController
    layout "settings"

    skip_before_action :current_budget
  end
end
