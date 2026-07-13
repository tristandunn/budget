# frozen_string_literal: true

require "rails_helper"

describe "targets/_response.turbo_stream+desktop.erb" do
  subject(:html) do
    render(
      locals:   {
        budget:                   budget,
        budget_snapshot:          budget_snapshot,
        category:                 subcategory,
        previous_budget_snapshot: previous_budget_snapshot
      },
      partial:  "targets/response",
      variants: [:desktop]
    )

    rendered
  end

  let(:budget)                   { subcategory.budget }
  let(:budget_snapshot)          { BudgetSnapshot.new(budget) }
  let(:previous_budget_snapshot) { nil }
  let(:subcategory)              { build_stubbed(:category, :subcategory) }

  before do
    stub_template("categories/_target.html.erb"    => "TARGET_PARTIAL")
    stub_template("categories/_available.html.erb" => "AVAILABLE_PARTIAL")
  end

  it "replaces the target frame" do
    expect(html).to have_turbo_stream_element(action: "replace", target: dom_id(subcategory, :target))
  end

  it "renders the target partial inside the target stream" do
    expect(html).to include("TARGET_PARTIAL")
  end

  it "replaces the subcategory available badge" do
    expect(html).to have_turbo_stream_element(action: "replace", target: dom_id(subcategory, :available))
  end

  it "renders the available partial inside the available badge stream" do
    expect(html).to include("AVAILABLE_PARTIAL")
  end
end
