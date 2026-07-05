# frozen_string_literal: true

require "rails_helper"

describe "categories/_category_header.html+desktop.erb" do
  subject(:html) do
    render(
      locals:   {
        budget_snapshot: budget_snapshot,
        category:        category
      },
      partial:  "categories/category_header",
      variants: [:desktop]
    )

    rendered
  end

  let(:budget_snapshot) { BudgetSnapshot.new(category.budget) }
  let(:category)        { create(:category) }

  it "identifies the header so it can be targeted by turbo streams" do
    expect(html).to have_css("tbody##{dom_id(category, :header)}")
  end

  it "renders a selection checkbox for the category" do
    expect(html).to have_css(
      "input[type=checkbox][data-selection-target=category]" \
      "[data-category-id='#{category.id}'][data-action='selection#toggleCategory']"
    )
  end

  it "labels the selection checkbox with the category name" do
    expect(html).to have_field(category.name, type: :checkbox)
  end

  it "renders the category name" do
    expect(html).to have_css("th", text: category.name)
  end

  it "renders the category amount assigned" do
    snapshot = budget_snapshot.snapshot_for(category.id)

    expect(html).to have_css("td", text: number_to_money(snapshot.amount_assigned))
  end

  it "renders the category spending activity" do
    snapshot = budget_snapshot.snapshot_for(category.id)

    expect(html).to have_css("td", text: number_to_money(-snapshot.amount_used))
  end

  it "renders the category cumulative available" do
    expect(html).to have_css(
      "td", text: number_to_money(budget_snapshot.available_for(category))
    )
  end

  it "wires the collapsible controller to the arrow" do
    expect(html).to have_css("[data-collapsible-arrow][data-action='click->collapsible#toggle']")
  end
end
