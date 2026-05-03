# frozen_string_literal: true

require "rails_helper"

describe "categories/_details.html.erb" do
  subject(:html) do
    render(
      locals:  {
        budget:                   budget,
        category:                 subcategory,
        budget_snapshot:          budget_snapshot,
        previous_budget_snapshot: previous_budget_snapshot
      },
      partial: "categories/details"
    )

    rendered
  end

  let(:budget)                   { subcategory.budget }
  let(:previous_budget_snapshot) { instance_double(BudgetSnapshot, available_for: 20_000) }
  let(:snapshot)                 { CategorySnapshot.new(amount_assigned: 40_000, amount_used: 10_000) }
  let(:subcategory)              { build_stubbed(:category, :subcategory) }

  let(:budget_snapshot) do
    instance_double(BudgetSnapshot, snapshot_for: snapshot, available_for: 50_000, date: Date.current)
  end

  it "renders the category name as the dialog title" do
    expect(html).to have_css("h2#category_dialog_title", text: subcategory.name)
  end

  it "renders the rollover amount" do
    expect(html).to have_css("div", text: /#{Regexp.escape(t("categories.show.rollover"))}\s*\$200\.00/)
  end

  it "renders the assigned amount" do
    expect(html).to have_css("div", text: /#{Regexp.escape(t("categories.show.assigned"))}\s*\$400\.00/)
  end

  it "renders the activity as the negation of amount used" do
    expect(html).to have_css("div", text: /#{Regexp.escape(t("categories.show.activity"))}\s*-\$100\.00/)
  end

  it "renders the available amount in a colored pill" do
    expect(html).to have_css("span.bg-lime-400", text: "$500.00")
  end

  it "links the rename button to the edit form with month and year" do
    expect(html).to have_link(
      t("categories.show.rename"),
      href: edit_budget_category_path(budget, subcategory,
                                      year:  budget_snapshot.date.year,
                                      month: budget_snapshot.date.month)
    )
  end

  it "targets the rename dialog frame from the rename link" do
    expect(html).to have_css("a[data-turbo-frame='category_rename_dialog']",
                             text: t("categories.show.rename"))
  end

  it "renders a Done button that closes the dialog" do
    expect(html).to have_css("button[data-action='dialog#close']", text: t("categories.show.done"))
  end

  context "without a previous budget snapshot" do
    let(:previous_budget_snapshot) { nil }

    it "renders a zero rollover amount" do
      expect(html).to have_css("div", text: /#{Regexp.escape(t("categories.show.rollover"))}\s*\$0\.00/)
    end
  end
end
