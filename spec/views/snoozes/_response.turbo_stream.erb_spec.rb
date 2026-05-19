# frozen_string_literal: true

require "rails_helper"

describe "snoozes/_response.turbo_stream.erb" do
  subject(:html) do
    render(
      locals:  {
        budget:          budget,
        budget_snapshot: budget_snapshot,
        category:        subcategory
      },
      partial: "snoozes/response"
    )

    rendered
  end

  let(:budget)          { subcategory.budget }
  let(:budget_snapshot) { BudgetSnapshot.new(budget) }
  let(:subcategory)     { build_stubbed(:category, :subcategory) }

  before do
    stub_template("categories/_target.html.erb"    => "TARGET_PARTIAL")
    stub_template("categories/_available.html.erb" => "AVAILABLE_PARTIAL")
  end

  it "replaces the subcategory target section" do
    expect(html).to have_turbo_stream_element(action: "replace", target: dom_id(subcategory, :target))
  end

  it "renders the target partial inside the target section stream" do
    expect(html).to include("TARGET_PARTIAL")
  end

  it "replaces the subcategory available badge" do
    expect(html).to have_turbo_stream_element(action: "replace", target: dom_id(subcategory, :available))
  end

  it "renders the available partial inside the available badge stream" do
    expect(html).to include("AVAILABLE_PARTIAL")
  end
end
