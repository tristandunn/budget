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
      expect(html).to have_css("div", normalize_ws: true, text: "#{t("categories.show.rollover")} $0.00")
    end
  end

  context "without a target" do
    it "renders the target prompt with the category name" do
      expect(html).to have_text(t("categories.show.target.question", name: subcategory.name))
    end

    it "links the create target button to the edit form with month and year" do
      expect(html).to have_link(
        t("categories.show.target.create"),
        href: edit_budget_category_target_path(budget, subcategory,
                                               year:  budget_snapshot.date.year,
                                               month: budget_snapshot.date.month)
      )
    end

    it "targets the target dialog frame from the create link" do
      expect(html).to have_css("a[data-turbo-frame='category_target_dialog']",
                               text: t("categories.show.target.create"))
    end
  end

  context "with a target" do
    let(:snapshot)    { CategorySnapshot.new(amount_assigned: 150_00, amount_used: 0) }
    let(:subcategory) { build_stubbed(:category, :subcategory, :with_monthly_spending_target) }

    before do
      allow(budget_snapshot).to receive(:target_progress_for)
        .with(subcategory)
        .and_return(TargetProgress.new(category: subcategory, snapshot: snapshot))
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

    it "links the edit target button to the edit form with month and year" do
      expect(html).to have_link(
        t("categories.show.target.edit"),
        href: edit_budget_category_target_path(budget, subcategory,
                                               year:  budget_snapshot.date.year,
                                               month: budget_snapshot.date.month)
      )
    end

    context "when fully funded" do
      let(:snapshot) { CategorySnapshot.new(amount_assigned: 200_00, amount_used: 0) }

      it "renders a checkmark instead of the percentage" do
        expect(html).to have_no_css("svg text")
      end
    end
  end
end
