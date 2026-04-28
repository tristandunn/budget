# frozen_string_literal: true

require "rails_helper"

describe AccountsController, type: :routing do
  it { is_expected.to route(:get, "/budgets/1/accounts").to(action: :index, budget_id: 1) }
  it { is_expected.to route(:get, "/budgets/1/accounts/new").to(action: :new, budget_id: 1) }
  it { is_expected.to route(:post, "/budgets/1/accounts").to(action: :create, budget_id: 1) }
  it { is_expected.to route(:get, "/budgets/1/accounts/2/edit").to(action: :edit, budget_id: 1, id: 2) }
  it { is_expected.to route(:patch, "/budgets/1/accounts/2").to(action: :update, budget_id: 1, id: 2) }
  it { is_expected.to route(:delete, "/budgets/1/accounts/2").to(action: :destroy, budget_id: 1, id: 2) }
end
