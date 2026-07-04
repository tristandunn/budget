# frozen_string_literal: true

require "rails_helper"

describe "categories/_details.html+desktop.erb" do
  subject(:html) do
    render(
      locals:   {
        budget:                   budget,
        category:                 subcategory,
        budget_snapshot:          budget_snapshot,
        previous_budget_snapshot: previous_budget_snapshot
      },
      partial:  "categories/details",
      variants: [:desktop]
    )

    rendered
  end

  let(:budget)                   { subcategory.budget }
  let(:previous_budget_snapshot) { instance_double(BudgetSnapshot, available_for: 20_000) }
  let(:snapshot)                 { CategorySnapshot.new(amount_assigned: 40_000, amount_used: 10_000) }
  let(:subcategory)              { build_stubbed(:category, :subcategory) }

  let(:budget_snapshot) do
    instance_double(BudgetSnapshot,
                    snapshot_for:  snapshot,
                    available_for: 50_000,
                    date:          Date.current)
  end

  before do
    stub_template("categories/_target.html.erb" => "TARGET_PARTIAL")
  end

  it "renders a collapsible balance header" do
    expect(html).to have_css(
      "div[data-controller='collapsible'][data-collapsible-id-value='category-#{subcategory.id}-balance']"
    ).and(
      have_css("h3[data-action='click->collapsible#toggle']", text: t("categories.show.balance"))
    )
  end

  it "renders the rollover amount" do
    expect(html).to have_css("div", normalize_ws: true, text: "#{t("categories.show.rollover")} $200.00")
  end

  it "renders the assigned amount" do
    expect(html).to have_css("div", normalize_ws: true, text: "#{t("categories.show.assigned")} $400.00")
  end

  it "renders the activity as the negation of amount used" do
    expect(html).to have_css("div", normalize_ws: true, text: "#{t("categories.show.activity")} -$100.00")
  end

  it "renders the available amount in a colored pill" do
    expect(html).to have_css("span.bg-lime-400", text: "$500.00")
  end

  it "renders a collapsible target header" do
    expect(html).to have_css(
      "div[data-controller='collapsible'][data-collapsible-id-value='category-#{subcategory.id}-target']"
    ).and(
      have_css("h3[data-action='click->collapsible#toggle']", text: t("categories.show.target.heading"))
    )
  end

  it "renders the target partial" do
    expect(html).to include("TARGET_PARTIAL")
  end

  context "without a previous budget snapshot" do
    let(:previous_budget_snapshot) { nil }

    it "renders a zero rollover amount" do
      expect(html).to have_css("div", normalize_ws: true, text: "#{t("categories.show.rollover")} $0.00")
    end
  end
end
