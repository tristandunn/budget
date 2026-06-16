# frozen_string_literal: true

require "rails_helper"

describe "budgets/_summary.html+desktop.erb" do
  subject(:html) do
    render(
      locals:   { budget_snapshot: budget_snapshot },
      partial:  "budgets/summary",
      variants: [:desktop]
    )

    rendered
  end

  let(:budget)          { create(:budget) }
  let(:budget_snapshot) { BudgetSnapshot.new(budget) }
  let(:parent)          { create(:category, budget: budget, with_snapshot: false) }
  let(:subcategory)     { create(:category, budget: budget, parent: parent, with_snapshot: false) }

  before do
    stub_template("budgets/_future_month.html.erb" => "FUTURE_MONTH_PARTIAL")

    create(:category_snapshot, budget:          budget,
                               category:        subcategory,
                               date:            1.month.ago.beginning_of_month,
                               amount_assigned: 100,
                               amount_used:     40)
    create(:category_snapshot, budget: budget, category: subcategory, amount_assigned: 300, amount_used: 150)
    create(:category_snapshot, budget: budget, category: parent, amount_assigned: 300, amount_used: 150)
  end

  it "renders the summary heading with the displayed month" do
    expect(html).to have_css(
      "h2",
      text: t("budgets.show.summary", month: l(budget_snapshot.date, format: :month))
    )
  end

  it "renders the rollover carried in from prior months" do
    expect(html).to have_css(
      "div", normalize_ws: true,
             text:         "#{t("budgets.show.rollover")} #{number_to_money(60)}"
    )
  end

  it "renders the assigned total for the month" do
    expect(html).to have_css(
      "div", normalize_ws: true,
             text:         "#{t("budgets.show.assigned")} #{number_to_money(300)}"
    )
  end

  it "renders the activity as the negated used total" do
    expect(html).to have_css(
      "div", normalize_ws: true,
             text:         "#{t("budgets.show.activity")} #{number_to_money(-150)}"
    )
  end

  it "renders the available total" do
    expect(html).to have_css(
      "div", normalize_ws: true,
             text:         "#{t("budgets.show.available")} #{number_to_money(210)}"
    )
  end

  it "makes the summary card collapsible from its heading" do
    expect(html).to have_css(
      "div[data-controller='collapsible'][data-collapsible-id-value='budget-summary']"
    ).and(have_css("h2[data-action='click->collapsible#toggle']"))
      .and(have_css("[data-collapsible-content='collapsible-budget-summary']"))
  end

  it "does not render the future months section without future assignments" do
    expect(html).to have_no_text(t("budgets.show.future_assigned"))
  end

  context "with assigned future months" do
    before do
      create(:category_snapshot, budget:          budget,
                                 category:        parent,
                                 date:            1.month.from_now.beginning_of_month,
                                 amount_assigned: 400)
      create(:category_snapshot, budget:          budget,
                                 category:        parent,
                                 date:            2.months.from_now.beginning_of_month,
                                 amount_assigned: 600)
    end

    it "renders the future months heading with the combined total" do
      expect(html).to have_css("h2", text: t("budgets.show.future_assigned"))
        .and(have_css("h2", text: number_to_money(1000)))
    end

    it "renders a row for each future month" do
      expect(html).to include("FUTURE_MONTH_PARTIAL")
    end

    it "makes the future months section collapsible" do
      expect(html).to have_css("[data-collapsible-id-value='future-months']")
        .and(have_css("[data-collapsible-content='collapsible-future-months']"))
    end
  end
end
