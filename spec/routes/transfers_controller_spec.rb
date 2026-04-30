# frozen_string_literal: true

require "rails_helper"

describe TransfersController, type: :routing do
  it { is_expected.to route(:get, "/budgets/1/transfers/new").to(action: :new, budget_id: 1) }
  it { is_expected.to route(:post, "/budgets/1/transfers").to(action: :create, budget_id: 1) }
end
