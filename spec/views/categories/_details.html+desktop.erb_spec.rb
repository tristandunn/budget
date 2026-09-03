# frozen_string_literal: true

require "rails_helper"

describe "categories/_details.html+desktop.erb" do
  subject(:html) do
    render(
      locals:   {
        budget:                subcategory.budget,
        category:              subcategory,
        budget_snapshot:       budget_snapshot,
        upcoming_transactions: upcoming_transactions
      },
      partial:  "categories/details",
      variants: [:desktop]
    )

    rendered
  end

  let(:snapshot)    { CategorySnapshot.new(amount_assigned: 40_000, amount_used: 10_000) }
  let(:subcategory) { build_stubbed(:category, :subcategory) }

  let(:budget_snapshot) do
    instance_double(BudgetSnapshot,
                    snapshot_for:  snapshot,
                    available_for: 50_000,
                    rollover_for:  20_000,
                    date:          Date.current)
  end

  let(:upcoming_transactions) do
    instance_double(UpcomingTransactions,
                    any?:            true,
                    count:           2,
                    total:           -5_000,
                    available_after: 45_000)
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

  it "renders the upcoming transaction count and total" do
    expect(html).to have_css(
      "div",
      normalize_ws: true,
      text:         "#{t("categories.show.upcoming", count: 2)} #{view.number_to_money(-5_000)}"
    )
  end

  it "renders the available amount after the upcoming transactions" do
    expect(html).to have_css(
      "div",
      normalize_ws: true,
      text:         "#{t("categories.show.available_after_upcoming")} #{view.number_to_money(45_000)}"
    )
  end

  it "renders the upcoming amounts as plain text" do
    expect(html).to have_no_css("span.rounded-full", text: view.number_to_money(-5_000))
      .and(have_no_css("span.rounded-full", text: view.number_to_money(45_000)))
  end

  context "with a single upcoming transaction" do
    let(:upcoming_transactions) do
      instance_double(UpcomingTransactions,
                      any?:            true,
                      count:           1,
                      total:           -5_000,
                      available_after: 45_000)
    end

    it "renders the singular count" do
      expect(html).to have_css("span", text: t("categories.show.upcoming", count: 1))
    end
  end

  context "when the upcoming transactions would overspend the category" do
    let(:upcoming_transactions) do
      instance_double(UpcomingTransactions,
                      any?:            true,
                      count:           2,
                      total:           -60_000,
                      available_after: -10_000)
    end

    it "renders the upcoming section in yellow" do
      expect(html).to have_css("div.bg-yellow-100", text: view.number_to_money(-10_000))
    end
  end

  context "without upcoming transactions" do
    let(:upcoming_transactions) { instance_double(UpcomingTransactions, any?: false) }

    it "omits the upcoming section" do
      expect(html).to have_no_text(t("categories.show.available_after_upcoming"))
    end
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
end
