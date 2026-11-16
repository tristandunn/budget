# frozen_string_literal: true

require "rails_helper"

describe Settings::AccountsController, type: :routing do
  it { expect(described_class).to route(:get, "/account").to(action: :show) }
  it { expect(described_class).to route(:patch, "/account").to(action: :update) }
end
