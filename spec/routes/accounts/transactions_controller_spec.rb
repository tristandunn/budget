# frozen_string_literal: true

require "rails_helper"

describe Accounts::TransactionsController, type: :routing do
  it do
    expect(described_class).to route(:get, "/budgets/1/accounts/2/transactions")
      .to(action: :index, budget_id: 1, account_id: 2)
  end
end
