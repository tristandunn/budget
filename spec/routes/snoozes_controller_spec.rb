# frozen_string_literal: true

require "rails_helper"

describe SnoozesController, type: :routing do
  subject(:routing) { described_class }

  it do
    expect(routing).to route(:post, "/budgets/1/categories/2/snooze")
      .to(action: :create, budget_id: 1, category_id: 2)
  end

  it do
    expect(routing).to route(:delete, "/budgets/1/categories/2/snooze")
      .to(action: :destroy, budget_id: 1, category_id: 2)
  end
end
