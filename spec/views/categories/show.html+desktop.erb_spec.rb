# frozen_string_literal: true

require "rails_helper"

describe "categories/show.html+desktop.erb" do
  subject(:html) do
    render template: "categories/show", formats: [:html], variants: [:desktop]

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

  it "renders the category panel turbo frame" do
    expect(html).to have_css("turbo-frame#category_panel")
  end

  it "renders the category name as the panel heading" do
    expect(html).to have_css("h2", text: subcategory.name)
  end

  it "links the rename button to the edit form with month and year" do
    expect(html).to have_css(
      "a[aria-label='#{t("categories.show.rename")}']" \
      "[href='#{edit_budget_category_path(budget, subcategory,
                                          year:  budget_snapshot.date.year,
                                          month: budget_snapshot.date.month)}']"
    )
  end

  it "targets the rename dialog frame from the rename button" do
    expect(html).to have_css(
      "a[aria-label='#{t("categories.show.rename")}'][data-turbo-frame='category_rename_dialog']"
    )
  end

  it "renders the details partial inside the category panel frame" do
    expect(html).to have_css("turbo-frame#category_panel", text: "DETAILS_PARTIAL")
  end
end
