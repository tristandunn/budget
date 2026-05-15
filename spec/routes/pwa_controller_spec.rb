# frozen_string_literal: true

require "rails_helper"

describe Rails::PwaController, type: :routing do
  it { expect(get: "/manifest.json").to route_to(controller: "rails/pwa", action: "manifest", format: "json") }
end
