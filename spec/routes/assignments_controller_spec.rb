# frozen_string_literal: true

require "rails_helper"

describe AssignmentsController, type: :routing do
  subject(:routing) { described_class }

  it do
    expect(routing).to route(:get, "/budgets/1/categories/2/assignment/edit")
      .to(action: :edit, budget_id: 1, category_id: 2)
  end

  it do
    expect(routing).to route(:patch, "/budgets/1/categories/2/assignment")
      .to(action: :update, budget_id: 1, category_id: 2)
  end
end
