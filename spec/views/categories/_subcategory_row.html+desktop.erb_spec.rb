# frozen_string_literal: true

require "rails_helper"

describe "categories/_subcategory_row.html+desktop.erb" do
  subject(:html) do
    render(
      locals:   {
        budget:          budget,
        budget_snapshot: budget_snapshot,
        subcategory:     subcategory
      },
      partial:  "categories/subcategory_row",
      variants: [:desktop]
    )

    rendered
  end

  let(:budget)          { subcategory.budget }
  let(:budget_snapshot) { BudgetSnapshot.new(budget) }
  let(:subcategory)     { create(:category, :subcategory) }

  before do
    stub_template("categories/_available.html.erb" => "AVAILABLE_PARTIAL")
  end

  it "identifies the row so it can be targeted by turbo streams" do
    expect(html).to have_css("tr##{dom_id(subcategory, :row)}")
  end

  it "renders a selection checkbox for the subcategory" do
    expect(html).to have_css(
      "input[type=checkbox][data-selection-target=subcategory]" \
      "[data-subcategory-id='#{subcategory.id}']"
    )
  end

  it "carries the panel detail url on the selection checkbox" do
    expect(html).to have_css(
      "input[data-selection-target=subcategory]" \
      "[data-detail-url='#{budget_category_path(budget, subcategory,
                                                year:  budget_snapshot.date.year,
                                                month: budget_snapshot.date.month)}']"
    )
  end

  it "labels the selection checkbox with the subcategory name" do
    expect(html).to have_css(
      "input[data-selection-target=subcategory]" \
      "[aria-label='#{t("categories.subcategory_row.select", name: subcategory.name)}']"
    )
  end

  it "renders the subcategory name inside the selection label" do
    expect(html).to have_css("label", text: subcategory.name)
  end

  it "identifies the subcategory name cell so it can be targeted by turbo streams" do
    expect(html).to have_css("th##{dom_id(subcategory, :name)}", text: subcategory.name)
  end

  it "selects the row when the assignment amount is edited" do
    expect(html).to have_css("a[data-action~='click->selection#selectRow']")
  end

  it "renders the subcategory amount assigned as a link" do
    subcategory_snapshot = budget_snapshot.snapshot_for(subcategory.id)

    expect(html).to have_link(
      number_to_money(subcategory_snapshot.amount_assigned),
      href: edit_budget_category_assignment_path(budget, subcategory,
                                                 year:  budget_snapshot.date.year,
                                                 month: budget_snapshot.date.month)
    )
  end

  it "wraps the subcategory assigned amount in a turbo frame" do
    expect(html).to have_css("td turbo-frame##{dom_id(subcategory, :assignment)}")
  end

  it "renders the subcategory spending activity" do
    subcategory_snapshot = budget_snapshot.snapshot_for(subcategory.id)

    expect(html).to have_css(
      "td",
      text: number_to_money(-subcategory_snapshot.amount_used)
    )
  end

  it "renders the subcategory available partial" do
    expect(html).to include("AVAILABLE_PARTIAL")
  end
end
