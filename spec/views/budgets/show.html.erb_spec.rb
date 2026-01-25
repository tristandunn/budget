# frozen_string_literal: true

require "rails_helper"

describe "budgets/show.html.erb" do
  subject(:html) do
    render template: "budgets/show", formats: [:html]

    rendered
  end

  let(:category)             { subcategory.parent }
  let(:category_snapshot)    { category.snapshots.first }
  let(:date)                 { Date.current.beginning_of_month }
  let(:subcategory)          { create(:category, :subcategory) }
  let(:subcategory_snapshot) { subcategory.snapshots.first }

  before do
    stub_template("shared/_toolbar.html.erb" => "TOOLBAR_PARTIAL")

    assign :budget,    category.budget
    assign :date,      date
    assign :snapshots, { category.id => category_snapshot, subcategory.id => subcategory_snapshot }
  end

  it "renders the header with the current month and year" do
    expect(html).to have_css("h1", text: date.strftime("%B %Y"))
  end

  it "renders the parent category name" do
    expect(html).to have_css("thead th", text: category.name)
  end

  it "renders the parent category amount assigned" do
    expect(html).to have_css(
      "thead th", text: number_to_currency(Money.from_cents(category_snapshot.amount_assigned))
    )
  end

  it "renders the parent category amount remaining" do
    expect(html).to have_css(
      "thead th",
      text: number_to_currency(Money.from_cents(category_snapshot.amount_remaining))
    )
  end

  it "renders the subcategory name" do
    expect(html).to have_css("tbody th", text: subcategory.name)
  end

  it "renders the subcategory amount assigned" do
    expect(html).to have_css(
      "tbody td",
      text: number_to_currency(Money.from_cents(subcategory_snapshot.amount_assigned))
    )
  end

  it "renders the subcategory amount remaining" do
    expect(html).to have_css(
      "tbody td",
      text: number_to_currency(Money.from_cents(subcategory_snapshot.amount_remaining))
    )
  end

  it "renders the toolbar" do
    expect(html).to include("TOOLBAR_PARTIAL")
  end
end
