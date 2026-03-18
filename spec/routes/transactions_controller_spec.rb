# frozen_string_literal: true

require "rails_helper"

describe TransactionsController, type: :routing do
  it { is_expected.to route(:get, "/budgets/1/transactions").to(action: :index, budget_id: 1) }
  it { is_expected.to route(:get, "/budgets/1/transactions/new").to(action: :new, budget_id: 1) }
  it { is_expected.to route(:post, "/budgets/1/transactions").to(action: :create, budget_id: 1) }
end
