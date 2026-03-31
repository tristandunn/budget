# frozen_string_literal: true

require "rails_helper"

describe Accounts::ReconciliationsController, type: :routing do
  it do
    expect(described_class).to route(:post, "/budgets/1/accounts/2/reconciliation")
      .to(action: :create, budget_id: 1, account_id: 2)
  end
end
