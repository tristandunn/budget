# frozen_string_literal: true

require "rails_helper"

describe CategoriesController, type: :routing do
  subject(:routing) { described_class }

  it do
    expect(routing).to route(:get, "/budgets/1/categories/2")
      .to(action: :show, budget_id: 1, id: 2)
  end

  it do
    expect(routing).to route(:get, "/budgets/1/categories/2/edit")
      .to(action: :edit, budget_id: 1, id: 2)
  end

  it do
    expect(routing).to route(:patch, "/budgets/1/categories/2")
      .to(action: :update, budget_id: 1, id: 2)
  end
end
