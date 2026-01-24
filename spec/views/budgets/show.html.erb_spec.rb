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

  it "links to the new transaction page" do
    expect(html).to have_link(href: new_budget_transaction_path(category.budget))
  end

  it "renders the plan link" do
    expect(html).to have_link("Plan", href: "#")
  end

  it "renders the spending link" do
    expect(html).to have_link("Spending", href: "#")
  end

  it "renders the accounts link" do
    expect(html).to have_link("Accounts", href: "#")
  end

  it "renders the reflect link" do
    expect(html).to have_link("Reflect", href: "#")
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
end
