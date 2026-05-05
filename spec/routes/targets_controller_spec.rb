# frozen_string_literal: true

require "rails_helper"

describe TargetsController, type: :routing do
  subject(:routing) { described_class }

  it do
    expect(routing).to route(:get, "/budgets/1/categories/2/target/edit")
      .to(action: :edit, budget_id: 1, category_id: 2)
  end

  it do
    expect(routing).to route(:patch, "/budgets/1/categories/2/target")
      .to(action: :update, budget_id: 1, category_id: 2)
  end

  it do
    expect(routing).to route(:delete, "/budgets/1/categories/2/target")
      .to(action: :destroy, budget_id: 1, category_id: 2)
  end
end
