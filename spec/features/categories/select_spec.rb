# frozen_string_literal: true

require "rails_helper"

describe "Category selection" do
  it "renders a selection checkbox for each subcategory" do
    subcategory = create(:category, :subcategory)
    budget      = subcategory.budget

    sign_in_for(budget)
    visit budget_path(budget)

    expect(page).to have_field(subcategory.name, type: :checkbox)
  end

  context "when selecting a subcategory", :js do
    let(:budget)   { create(:budget) }
    let(:category) { create(:category, budget: budget) }

    let(:first_subcategory) do
      create(:category, :subcategory, :with_monthly_savings_target,
             budget: budget, parent: category, with_snapshot: false)
    end

    let(:second_subcategory) do
      create(:category, :subcategory, budget: budget, parent: category, with_snapshot: false)
    end

    before do
      create(:category_snapshot, budget:          budget,
                                 category:        first_subcategory,
                                 amount_assigned: 40_000,
                                 amount_used:     10_000)
      create(:category_snapshot, budget:          budget,
                                 category:        second_subcategory,
                                 amount_assigned: 25_000,
                                 amount_used:     5_000)

      sign_in_for(budget)
      visit budget_path(budget)
    end

    it "selects the subcategory by clicking its name without opening the dialog" do
      find("label", text: first_subcategory.name).click

      expect(page).to have_css("#category_panel", text: first_subcategory.name)
        .and(have_no_css("#category_dialog_title"))
    end

    it "selects the subcategory when editing its assignment amount" do
      find("a", text: "$400.00").click

      expect(page).to have_css("#category_panel", text: first_subcategory.name)
    end

    it "keeps the subcategory selected and refreshes the panel after editing the assignment" do
      find("a", text: "$400.00").click

      field = find("input[inputmode='decimal']")
      field.set("500.00")
      field.send_keys(:enter)

      expect(page).to have_css("tr[data-selected]", text: first_subcategory.name)
        .and(have_css("#category_panel", text: "$500.00"))
    end

    it "reveals the sidebar detail for the selected subcategory" do
      check(first_subcategory.name)

      within "#category_panel" do
        expect(page).to have_text("$300.00")
          .and(have_text(t("categories.show.target.needed")))
      end
    end

    it "highlights the selected subcategory row" do
      check(first_subcategory.name)

      expect(page).to have_css("tr[data-selected]", text: first_subcategory.name)
    end

    it "hides the month summary while a subcategory is selected" do
      check(first_subcategory.name)

      expect(page).to have_no_css(
        "[data-selection-target='summary']",
        text: t("budgets.show.rollover")
      )
    end

    it "swaps the detail and unchecks the previous subcategory when another is selected" do
      check(first_subcategory.name)

      wait_for(have_css("#category_panel", text: first_subcategory.name)) do
        check(second_subcategory.name)
      end

      expect(page).to have_css("#category_panel", text: "$200.00")
        .and(have_unchecked_field(first_subcategory.name))
    end

    it "restores the month summary when the subcategory is deselected" do
      check(first_subcategory.name)

      wait_for(have_css("#category_panel", text: first_subcategory.name)) do
        uncheck(first_subcategory.name)
      end

      expect(page).to have_css("turbo-frame#category_panel.hidden", visible: :all)
        .and(have_css("[data-selection-target='summary']", text: t("budgets.show.rollover")))
    end
  end

  context "when on a mobile browser", :mobile do
    it "does not render a selection checkbox for each subcategory" do
      subcategory = create(:category, :subcategory)
      budget      = subcategory.budget

      sign_in_for(budget)
      visit budget_path(budget)

      expect(page).to have_text(subcategory.name).and(have_no_field(subcategory.name, type: :checkbox))
    end
  end
end
