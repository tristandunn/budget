# frozen_string_literal: true

require "rails_helper"

describe BudgetsController, type: :routing do
  subject(:routing) { described_class }

  it { is_expected.to route(:get, "/").to(action: :index) }
  it { is_expected.to route(:get, "/budgets/1").to(action: :show, id: 1) }
  it { is_expected.to route(:get, "/budgets/1/edit").to(action: :edit, id: 1) }
  it { is_expected.to route(:patch, "/budgets/1").to(action: :update, id: 1) }

  it do
    expect(routing).to route(:get, "/budgets/1/2025/3")
      .to(action: :show, id: "1", year: "2025", month: "3")
  end

  it "does not route a two-digit year" do
    expect(get("/budgets/1/25/3")).not_to be_routable
  end

  it "does not route a non-numeric month" do
    expect(get("/budgets/1/2025/abc")).not_to be_routable
  end
end
