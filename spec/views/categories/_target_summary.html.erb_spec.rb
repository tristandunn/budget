# frozen_string_literal: true

require "rails_helper"

describe "categories/_target_summary.html.erb" do
  subject(:html) do
    render(
      locals:  {
        category:        subcategory,
        budget_snapshot: budget_snapshot
      },
      partial: "categories/target_summary"
    )

    rendered
  end

  let(:budget_snapshot) { instance_double(BudgetSnapshot, snoozed?: false) }
  let(:snapshot)        { CategorySnapshot.new(amount_assigned: 150_00, amount_used: 0) }
  let(:subcategory)     { build_stubbed(:category, :subcategory, :with_monthly_spending_target) }

  before do
    allow(budget_snapshot).to receive(:target_progress_for)
      .with(subcategory)
      .and_return(TargetProgress.new(category: subcategory, rollover: 0, snapshot: snapshot))
  end

  it "renders the refill type chip" do
    expect(html).to have_css("span", text: t("categories.show.target.monthly_spending_label"))
  end

  it "renders the needed amount" do
    expect(html).to have_css("div",
                             normalize_ws: true,
                             text:         "#{t("categories.show.target.needed")} $200.00")
  end

  it "renders the funded amount from the snapshot" do
    expect(html).to have_css("div",
                             normalize_ws: true,
                             text:         "#{t("categories.show.target.funded")} $150.00")
  end

  it "renders the to-go amount" do
    expect(html).to have_css("div",
                             normalize_ws: true,
                             text:         "#{t("categories.show.target.to_go")} $50.00")
  end

  it "renders the funded percentage when underfunded" do
    expect(html).to have_css("svg text", text: "75%")
  end

  it "does not dim the progress ring when not snoozed" do
    expect(html).to have_no_css("div.opacity-50")
  end

  context "when fully funded" do
    let(:snapshot) { CategorySnapshot.new(amount_assigned: 200_00, amount_used: 0) }

    it "renders a checkmark instead of the percentage" do
      expect(html).to have_no_css("svg text")
    end
  end

  context "with a monthly savings target" do
    let(:subcategory) { build_stubbed(:category, :subcategory, :with_monthly_savings_target) }

    it "renders the set-aside type chip" do
      expect(html).to have_css("span", text: t("categories.show.target.monthly_savings_label"))
    end
  end

  context "when snoozed" do
    before do
      allow(budget_snapshot).to receive(:snoozed?).with(subcategory).and_return(true)
    end

    it "dims the progress ring" do
      expect(html).to have_css("div.opacity-50")
    end
  end
end
