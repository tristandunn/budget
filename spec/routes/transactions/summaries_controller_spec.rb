# frozen_string_literal: true

require "rails_helper"

describe Transactions::SummariesController, type: :routing do
  it do
    expect(described_class).to route(:get, "/budgets/1/transactions/summary")
      .to(action: :show, budget_id: 1)
  end
end
