# frozen_string_literal: true

require "rails_helper"

describe PayeesController, type: :routing do
  subject(:routing) { described_class }

  it do
    expect(routing).to route(:get, "/budgets/1/payees/2/defaults")
      .to(action: :defaults, budget_id: 1, id: 2)
  end
end
