# frozen_string_literal: true

require "rails_helper"

describe UsersController, type: :routing do
  it { expect(described_class).to route(:get, "/user/edit").to(action: :edit) }
  it { expect(described_class).to route(:patch, "/user").to(action: :update) }
end
