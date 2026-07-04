# frozen_string_literal: true

require "rails_helper"

describe "categories/update.turbo_stream+desktop.erb" do
  subject(:html) do
    render template: "categories/update", formats: [:turbo_stream], variants: [:desktop]

    rendered
  end

  let(:budget)          { subcategory.budget }
  let(:budget_snapshot) { BudgetSnapshot.new(budget) }
  let(:subcategory)     { create(:category, :subcategory) }

  before do
    stub_template("categories/_subcategory_row.html.erb" => "SUBCATEGORY_ROW_PARTIAL")

    assign :budget,          budget
    assign :category,        subcategory
    assign :budget_snapshot, budget_snapshot
  end

  it "replaces the subcategory row" do
    expect(html).to have_turbo_stream_element(action: "replace", target: dom_id(subcategory, :row))
  end

  it "renders the subcategory row partial inside the row stream" do
    expect(html).to include("SUBCATEGORY_ROW_PARTIAL")
  end

  it "updates the rename dialog frame" do
    expect(html).to have_turbo_stream_element(action: "update", target: "category_rename_dialog")
  end

  it "renders the dismisser controller inside the rename dialog stream" do
    expect(html).to include('data-controller="dialog-dismisser"')
  end
end
