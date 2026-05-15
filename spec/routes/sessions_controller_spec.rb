# frozen_string_literal: true

require "rails_helper"

describe SessionsController, type: :routing do
  it { is_expected.to route(:get, "/session/new").to(action: :new) }
  it { is_expected.to route(:post, "/session").to(action: :create) }
  it { is_expected.to route(:delete, "/session").to(action: :destroy) }
end
