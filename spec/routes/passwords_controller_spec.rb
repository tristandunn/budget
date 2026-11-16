# frozen_string_literal: true

require "rails_helper"

describe PasswordsController, type: :routing do
  it { expect(described_class).to route(:get, "/account/password").to(action: :show) }
  it { expect(described_class).to route(:patch, "/account/password").to(action: :update) }
end
