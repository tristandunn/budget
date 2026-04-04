# frozen_string_literal: true

require "rails_helper"

describe SettingsController, type: :routing do
  it do
    expect(described_class).to route(:patch, "/budgets/1/settings")
      .to(action: :update, budget_id: 1)
  end
end
