# frozen_string_literal: true

require "rails_helper"

describe Settings::SessionsController, type: :routing do
  it { expect(described_class).to route(:get, "/account/sessions").to(action: :index) }

  it do
    expect(described_class).to route(:delete, "/account/sessions/1").to(action: :destroy, id: 1)
  end
end
