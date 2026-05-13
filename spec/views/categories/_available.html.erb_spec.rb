# frozen_string_literal: true

require "rails_helper"

describe "categories/_available.html.erb" do
  subject(:html) do
    render(
      locals:  {
        category:        category,
        budget_snapshot: budget_snapshot
      },
      partial: "categories/available"
    )

    rendered
  end

  let(:budget_snapshot) do
    instance_double(BudgetSnapshot, available_for: 50_00, underfunded?: underfunded)
  end

  let(:category)    { build_stubbed(:category, :subcategory) }
  let(:underfunded) { false }

  it "identifies the badge with a stable dom id" do
    expect(html).to have_css("div##{dom_id(category, :available)}")
  end

  it "renders the available amount" do
    expect(html).to have_css("div", text: "$50.00")
  end

  it "uses the positive amount color when there is no underfunded target" do
    expect(html).to have_css("div.bg-lime-400")
  end

  it "does not render a progress icon when the category has no target" do
    expect(html).to have_no_css("svg")
  end

  context "when the category is underfunded" do
    let(:underfunded) { true }

    it "uses the underfunded color" do
      expect(html).to have_css("div.bg-yellow-200")
    end
  end

  context "with a target" do
    let(:category) { build_stubbed(:category, :subcategory, :with_monthly_spending_target) }

    before do
      allow(budget_snapshot).to receive(:target_progress_for)
        .with(category)
        .and_return(TargetProgress.new(category: category, snapshot: snapshot))
    end

    context "when fully funded" do
      let(:snapshot) { CategorySnapshot.new(amount_assigned: 200_00, amount_used: 0) }

      it "renders the funded label as the icon title" do
        expect(html).to have_css("svg title", text: t("categories.show.target.funded_label"))
      end

      it "renders the checkmark path" do
        expect(html).to have_css("svg path")
      end

      it "does not render the pie wedge" do
        expect(html).to have_no_css("svg circle[stroke-dasharray]")
      end
    end

    context "when overspent" do
      let(:budget_snapshot) do
        instance_double(BudgetSnapshot, available_for: -10_00, underfunded?: false)
      end
      let(:snapshot)        { CategorySnapshot.new(amount_assigned: 150_00, amount_used: 160_00) }

      it "does not render a progress icon" do
        expect(html).to have_no_css("svg")
      end

      it "uses the overspent color" do
        expect(html).to have_css("div.bg-red-200")
      end
    end

    context "when underfunded" do
      let(:snapshot)    { CategorySnapshot.new(amount_assigned: 150_00, amount_used: 0) }
      let(:underfunded) { true }

      it "renders a labelled title describing the progress" do
        expect(html).to have_css("svg title",
                                 text: t("categories.show.target.percent_funded", percentage: 75))
      end

      it "renders the pie wedge sized to the funded percentage" do
        expect(html).to have_css("svg circle[stroke-dasharray='75 100']")
      end

      it "does not render the checkmark" do
        expect(html).to have_no_css("svg path")
      end
    end
  end
end
