# frozen_string_literal: true

require "rails_helper"

describe PayeesController, type: :routing do
  it do
    expect(described_class).to route(:get, "/budgets/1/payees")
      .to(action: :index, budget_id: 1)
  end
end
