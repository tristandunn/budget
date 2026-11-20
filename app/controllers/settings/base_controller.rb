# frozen_string_literal: true

module Settings
  class BaseController < ApplicationController
    layout "settings"

    skip_before_action :load_budget
  end
end
