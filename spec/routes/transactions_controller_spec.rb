# frozen_string_literal: true

require "rails_helper"

describe TransactionsController, type: :routing do
  it { is_expected.to route(:get, "/budgets/1/transactions").to(action: :index, budget_id: 1) }
  it { is_expected.to route(:get, "/budgets/1/transactions/new").to(action: :new, budget_id: 1) }
  it { is_expected.to route(:post, "/budgets/1/transactions").to(action: :create, budget_id: 1) }
  it { is_expected.to route(:get, "/budgets/1/transactions/1/edit").to(action: :edit, budget_id: 1, id: 1) }
  it { is_expected.to route(:patch, "/budgets/1/transactions/1").to(action: :update, budget_id: 1, id: 1) }
  it { is_expected.to route(:delete, "/budgets/1/transactions/1").to(action: :destroy, budget_id: 1, id: 1) }
end
