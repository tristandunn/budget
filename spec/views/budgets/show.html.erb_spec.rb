# frozen_string_literal: true

require "rails_helper"

describe "budgets/show.html.erb" do
  subject(:html) do
    render template: "budgets/show", formats: [:html]

    rendered
  end

  let(:budget_snapshot) { BudgetSnapshot.new(subcategory.budget) }
  let(:subcategory)     { create(:category, :subcategory) }

  before do
    stub_template("shared/_toolbar.html.erb" => "TOOLBAR_PARTIAL")

    assign :budget,          subcategory.budget
    assign :budget_snapshot, budget_snapshot
  end

  it "renders the header with the current month and year" do
    expect(html).to have_css("h1", text: Date.current.beginning_of_month.strftime("%b %Y"))
  end

  it "renders the available to assign amount" do
    expect(html).to have_css(
      "header", text: number_to_currency(Money.from_cents(subcategory.budget.available_to_assign))
    )
  end

  it "renders the parent category name" do
    expect(html).to have_css("thead th", text: subcategory.parent.name)
  end

  it "renders the parent category amount assigned" do
    parent_snapshot = budget_snapshot.snapshot_for(subcategory.parent_id)

    expect(html).to have_css(
      "thead th", text: number_to_currency(Money.from_cents(parent_snapshot.amount_assigned))
    )
  end

  it "renders the parent category amount remaining" do
    parent_snapshot = budget_snapshot.snapshot_for(subcategory.parent_id)

    expect(html).to have_css(
      "thead th",
      text: number_to_currency(Money.from_cents(parent_snapshot.amount_remaining))
    )
  end

  it "renders the subcategory name" do
    expect(html).to have_css("tbody th", text: subcategory.name)
  end

  it "renders the subcategory amount assigned as a link" do
    subcategory_snapshot = budget_snapshot.snapshot_for(subcategory.id)

    expect(html).to have_css(
      "tbody td a",
      text: number_to_currency(Money.from_cents(subcategory_snapshot.amount_assigned))
    )
  end

  it "renders the subcategory amount remaining" do
    subcategory_snapshot = budget_snapshot.snapshot_for(subcategory.id)

    expect(html).to have_css(
      "tbody td",
      text: number_to_currency(Money.from_cents(subcategory_snapshot.amount_remaining))
    )
  end

  it "wraps the subcategory assigned amount in a turbo frame" do
    expect(html).to have_css("tbody td turbo-frame##{dom_id(subcategory, :assignment)}")
  end

  it "renders the toolbar" do
    expect(html).to include("TOOLBAR_PARTIAL")
  end

  context "when on the first month" do
    it "disables the previous month link" do
      expect(html).to have_css('a#previous-month[aria-disabled="true"]')
    end

    it "enables the next month link" do
      expect(html).to have_css("a#next-month:not([aria-disabled])")
    end
  end

  context "when on a middle month" do
    before do
      create(:category_snapshot, budget: subcategory.budget, date: 2.months.ago.beginning_of_month)
    end

    it "enables the previous month link" do
      expect(html).to have_css("a#previous-month:not([aria-disabled])")
    end

    it "enables the next month link" do
      expect(html).to have_css("a#next-month:not([aria-disabled])")
    end
  end

  context "when on the last month" do
    let(:next_month) { 1.month.from_now.beginning_of_month }

    let(:budget_snapshot) do
      BudgetSnapshot.new(
        subcategory.budget,
        month: next_month.month.to_s,
        year:  next_month.year.to_s
      )
    end

    it "enables the previous month link" do
      expect(html).to have_css("a#previous-month:not([aria-disabled])")
    end

    it "disables the next month link" do
      expect(html).to have_css('a#next-month[aria-disabled="true"]')
    end
  end
end
