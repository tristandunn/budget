# frozen_string_literal: true

require "rails_helper"

describe "assignments/update.turbo_stream.erb" do
  subject(:html) do
    render template: "assignments/update", formats: [:turbo_stream]

    rendered
  end

  let(:budget)          { subcategory.budget }
  let(:budget_snapshot) { BudgetSnapshot.new(budget) }
  let(:subcategory)     { create(:category, :subcategory) }

  before do
    stub_template("budgets/_available_to_assign.html.erb" => "AVAILABLE_TO_ASSIGN_PARTIAL")
    stub_template("categories/_category_header.html.erb"  => "CATEGORY_HEADER_PARTIAL")
    stub_template("categories/_subcategory_row.html.erb"  => "SUBCATEGORY_ROW_PARTIAL")

    assign :budget,          budget
    assign :budget_snapshot, budget_snapshot
    assign :subcategory,     subcategory
  end

  it "replaces the subcategory row" do
    expect(html).to have_turbo_stream_element(
      action: "replace",
      target: dom_id(subcategory, :row)
    )
  end

  it "renders the subcategory row partial" do
    expect(html).to include("SUBCATEGORY_ROW_PARTIAL")
  end

  it "replaces the parent category header" do
    expect(html).to have_turbo_stream_element(
      action: "replace",
      target: dom_id(subcategory.parent, :header)
    )
  end

  it "renders the category header partial" do
    expect(html).to include("CATEGORY_HEADER_PARTIAL")
  end

  it "replaces the available to assign badge" do
    expect(html).to have_turbo_stream_element(action: "replace", target: "available_to_assign")
  end

  it "renders the available to assign partial" do
    expect(html).to include("AVAILABLE_TO_ASSIGN_PARTIAL")
  end
end
