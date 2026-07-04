# frozen_string_literal: true

require "rails_helper"

describe "categories/show.html.erb" do
  subject(:html) do
    render template: "categories/show", formats: [:html]

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

  it "renders the category dialog turbo frame" do
    expect(html).to have_css("turbo-frame#category_dialog")
  end

  it "renders the category name as the dialog title" do
    expect(html).to have_css("h2#category_dialog_title", text: subcategory.name)
  end

  it "renders a Done button that closes the dialog" do
    expect(html).to have_css("button[data-action='dialog#close']", text: t("categories.show.done"))
  end

  it "renders the details partial inside the category dialog frame" do
    expect(html).to have_css("turbo-frame#category_dialog", text: "DETAILS_PARTIAL")
  end
end
