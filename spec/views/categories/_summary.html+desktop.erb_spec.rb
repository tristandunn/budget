# frozen_string_literal: true

require "rails_helper"

describe "categories/_summary.html+desktop.erb" do
  subject(:html) do
    render(
      locals:   { summary: summary, budget_snapshot: budget_snapshot },
      partial:  "categories/summary",
      variants: [:desktop]
    )

    rendered
  end

  let(:budget_snapshot) { instance_double(BudgetSnapshot, date: Date.current) }

  let(:summary) do
    instance_double(CategorySummary,
                    size:      2,
                    names:     %w(Groceries Rent),
                    rollover:  23_000,
                    assigned:  65_000,
                    activity:  -15_000,
                    available: 50_000)
  end

  it "renders the selection count as the heading" do
    expect(html).to have_css("h2", text: t("categories.summary.title", count: 2))
  end

  it "lists the selected category names as a sentence" do
    expect(html).to have_css("p", text: "Groceries and Rent")
  end

  it "renders a collapsible summary shared across selections" do
    expect(html).to have_css(
      "div[data-controller='collapsible'][data-collapsible-id-value='selection-summary']"
    ).and(
      have_css("h3[data-action='click->collapsible#toggle']",
               text: t("categories.summary.heading", month: l(budget_snapshot.date, format: :month)))
    ).and(
      have_css("[data-collapsible-content='collapsible-selection-summary']")
    )
  end

  it "renders the summed rollover amount" do
    expect(html).to have_css("div", normalize_ws: true, text: "#{t("categories.show.rollover")} $230.00")
  end

  it "renders the summed assigned amount" do
    expect(html).to have_css("div", normalize_ws: true, text: "#{t("categories.show.assigned")} $650.00")
  end

  it "renders the summed activity amount" do
    expect(html).to have_css("div", normalize_ws: true, text: "#{t("categories.show.activity")} -$150.00")
  end

  it "renders the summed available amount in a colored pill" do
    expect(html).to have_css("span.bg-lime-400", text: "$500.00")
  end
end
