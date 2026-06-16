# frozen_string_literal: true

require "rails_helper"

describe "budgets/_future_month.html+desktop.erb" do
  subject(:html) do
    render(
      locals:   { month_snapshot: month_snapshot },
      partial:  "budgets/future_month",
      variants: [:desktop]
    )

    rendered
  end

  let(:budget)         { create(:budget) }
  let(:month)          { 1.month.from_now.beginning_of_month }
  let(:month_snapshot) { BudgetSnapshot.new(budget, month: month.month, year: month.year) }
  let(:parent)         { create(:category, budget: budget, with_snapshot: false) }

  let(:subcategory) do
    create(:category, :with_monthly_spending_target, budget: budget, parent: parent, with_snapshot: false)
  end

  before do
    stub_template("shared/_progress_pie.html.erb" => "PROGRESS_PIE_PARTIAL")

    create(:category_snapshot, budget:          budget,
                               category:        subcategory,
                               date:            month,
                               amount_assigned: 150_00,
                               amount_used:     0)
    create(:category_snapshot, budget: budget, category: parent, date: month, amount_assigned: 150_00, amount_used: 0)
  end

  it "renders the month name" do
    expect(html).to have_text(month.strftime("%B"))
  end

  it "renders the assigned amount for the month" do
    expect(html).to have_text(number_to_money(150_00))
  end

  it "renders the funding progress pie" do
    expect(html).to include("PROGRESS_PIE_PARTIAL")
  end
end
