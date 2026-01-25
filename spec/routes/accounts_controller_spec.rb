# frozen_string_literal: true

require "rails_helper"

describe AccountsController, type: :routing do
  it { is_expected.to route(:get, "/budgets/1/accounts").to(action: :index, budget_id: 1) }
end
