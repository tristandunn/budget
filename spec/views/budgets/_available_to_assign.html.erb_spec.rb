# frozen_string_literal: true

require "rails_helper"

describe "budgets/_available_to_assign.html.erb" do
  subject(:html) do
    render(locals: { budget: budget }, partial: "budgets/available_to_assign")

    rendered
  end

  let(:budget) { build_stubbed(:budget, available_to_assign: 100_000) }

  it "identifies the badge so it can be targeted by turbo streams" do
    expect(html).to have_css("div#available_to_assign")
  end

  it "renders the available to assign amount" do
    expect(html).to have_css(
      "div#available_to_assign", text: number_to_money(budget.available_to_assign)
    )
  end

  it "labels the badge with the localized title" do
    expect(html).to have_css(
      "div#available_to_assign[title='#{t("budgets.available_to_assign.title")}']"
    )
  end

  context "when the available amount is positive" do
    it "colors the badge for a positive amount" do
      expect(html).to have_css("div#available_to_assign.bg-lime-400")
    end
  end

  context "when the available amount is zero" do
    let(:budget) { build_stubbed(:budget, available_to_assign: 0) }

    it "colors the badge for a zero amount" do
      expect(html).to have_css("div#available_to_assign.bg-stone-200")
    end
  end

  context "when the available amount is negative" do
    let(:budget) { build_stubbed(:budget, available_to_assign: -100) }

    it "colors the badge for a negative amount" do
      expect(html).to have_css("div#available_to_assign.bg-red-200")
    end
  end
end
