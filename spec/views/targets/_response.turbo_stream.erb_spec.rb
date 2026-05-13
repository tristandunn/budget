# frozen_string_literal: true

require "rails_helper"

describe "targets/_response.turbo_stream.erb" do
  subject(:html) do
    render(
      locals:  {
        budget:                   budget,
        budget_snapshot:          budget_snapshot,
        category:                 subcategory,
        previous_budget_snapshot: previous_budget_snapshot
      },
      partial: "targets/response"
    )

    rendered
  end

  let(:budget)                   { subcategory.budget }
  let(:budget_snapshot)          { BudgetSnapshot.new(budget) }
  let(:previous_budget_snapshot) { nil }
  let(:subcategory)              { build_stubbed(:category, :subcategory) }

  before do
    stub_template("categories/_details.html.erb"   => "DETAILS_PARTIAL")
    stub_template("categories/_available.html.erb" => "AVAILABLE_PARTIAL")
  end

  it "updates the category dialog frame" do
    expect(html).to have_turbo_stream_element(action: "update", target: "category_dialog")
  end

  it "renders the details partial inside the category dialog stream" do
    expect(html).to include("DETAILS_PARTIAL")
  end

  it "replaces the subcategory available badge" do
    expect(html).to have_turbo_stream_element(action: "replace", target: dom_id(subcategory, :available))
  end

  it "renders the available partial inside the available badge stream" do
    expect(html).to include("AVAILABLE_PARTIAL")
  end

  it "updates the target dialog frame" do
    expect(html).to have_turbo_stream_element(action: "update", target: "category_target_dialog")
  end

  it "renders the dismisser controller inside the target dialog stream" do
    expect(html).to include('data-controller="dialog-dismisser"')
  end
end
