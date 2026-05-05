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

  let(:category)        { build_stubbed(:category, :subcategory) }
  let(:underfunded)     { false }

  it "identifies the badge with a stable dom id" do
    expect(html).to have_css("div##{dom_id(category, :available)}")
  end

  it "renders the available amount" do
    expect(html).to have_css("div", text: "$50.00")
  end

  it "uses the positive amount color when there is no underfunded target" do
    expect(html).to have_css("div.bg-lime-400")
  end

  context "when the category is underfunded" do
    let(:underfunded) { true }

    it "uses the underfunded color" do
      expect(html).to have_css("div.bg-yellow-200")
    end
  end
end
