# frozen_string_literal: true

require "rails_helper"

describe "categories/_details.html.erb" do
  subject(:html) do
    render(
      locals:  {
        budget:                   subcategory.budget,
        category:                 subcategory,
        budget_snapshot:          budget_snapshot,
        previous_budget_snapshot: previous_budget_snapshot
      },
      partial: "categories/details"
    )

    rendered
  end

  let(:previous_budget_snapshot) { instance_double(BudgetSnapshot, available_for: 20_000) }
  let(:snapshot)                 { CategorySnapshot.new(amount_assigned: 40_000, amount_used: 10_000) }
  let(:subcategory)              { build_stubbed(:category, :subcategory) }

  let(:budget_snapshot) do
    instance_double(BudgetSnapshot,
                    snapshot_for:              snapshot,
                    available_for:             50_000,
                    date:                      Date.current,
                    upcoming_transactions_for: upcoming_transactions)
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

  it "renders the upcoming heading" do
    expect(html).to have_css("h3", text: t("categories.show.upcoming_heading"))
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

  it "renders the target partial" do
    expect(html).to include("TARGET_PARTIAL")
  end

  it "links the rename button to the edit form with month and year" do
    expect(html).to have_link(
      t("categories.show.rename"),
      href: edit_budget_category_path(subcategory.budget, subcategory,
                                      year:  budget_snapshot.date.year,
                                      month: budget_snapshot.date.month)
    )
  end

  it "targets the rename dialog frame from the rename link" do
    expect(html).to have_css("a[data-turbo-frame='category_rename_dialog']",
                             text: t("categories.show.rename"))
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

  context "without a previous budget snapshot" do
    let(:previous_budget_snapshot) { nil }

    it "renders a zero rollover amount" do
      expect(html).to have_css("div", normalize_ws: true, text: "#{t("categories.show.rollover")} $0.00")
    end
  end

  context "without upcoming transactions" do
    let(:upcoming_transactions) { instance_double(UpcomingTransactions, any?: false) }

    it "omits the upcoming section" do
      expect(html).to have_no_text(t("categories.show.available_after_upcoming"))
        .and(have_no_text(t("categories.show.upcoming_heading")))
    end
  end
end
