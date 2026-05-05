# frozen_string_literal: true

require "rails_helper"

describe "categories/update.turbo_stream.erb" do
  subject(:html) do
    render template: "categories/update", formats: [:turbo_stream]

    rendered
  end

  let(:budget)          { subcategory.budget }
  let(:budget_snapshot) { BudgetSnapshot.new(budget) }
  let(:subcategory)     { build_stubbed(:category, :subcategory) }

  before do
    stub_template("categories/_details.html.erb" => "DETAILS_PARTIAL")

    assign :budget,          budget
    assign :category,        subcategory
    assign :budget_snapshot, budget_snapshot
  end

  it "updates the category dialog frame" do
    expect(html).to have_css("turbo-stream[action='update'][target='category_dialog']")
  end

  it "renders the details partial inside the category dialog stream" do
    expect(html).to include("DETAILS_PARTIAL")
  end

  it "updates the subcategory name in the budget table" do
    expect(html).to have_css(
      "turbo-stream[action='update'][target='#{dom_id(subcategory, :name)}']"
    )
  end

  it "renders the new subcategory link with month and year" do
    href = budget_category_path(budget, subcategory,
                                year:  budget_snapshot.date.year,
                                month: budget_snapshot.date.month)

    expect(html).to include(%(href="#{ERB::Util.html_escape(href)}"))
  end

  it "updates the rename dialog frame" do
    expect(html).to have_css("turbo-stream[action='update'][target='category_rename_dialog']")
  end

  it "renders the dismisser controller inside the rename dialog stream" do
    expect(html).to include('data-controller="dialog-dismisser"')
  end
end
