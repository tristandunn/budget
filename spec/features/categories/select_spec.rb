# frozen_string_literal: true

require "rails_helper"

describe "Category selection" do
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

    it "selects only the subcategory and opens its assignment when its name is clicked" do
      click_button(first_subcategory.name)

      expect(page).to have_css("#category_panel", text: first_subcategory.name)
        .and(have_css("input[inputmode='decimal']"))
    end

    it "switches to only the clicked name during a multiple selection" do
      check(first_subcategory.name)

      wait_for(have_css("#category_panel", text: first_subcategory.name)) do
        check(second_subcategory.name)
      end

      click_button(second_subcategory.name)

      expect(page).to have_css("#category_panel", text: second_subcategory.name)
        .and(have_checked_field(second_subcategory.name))
        .and(have_unchecked_field(first_subcategory.name))
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

    it "discards the assignment edit and keeps the subcategory selected on escape" do
      find("a", text: "$400.00").click

      field = find("input[inputmode='decimal']")
      field.set("500.00")
      field.send_keys(:escape)

      expect(page).to have_css("tr[data-selected]", text: first_subcategory.name)
        .and(have_no_css("input[inputmode='decimal']"))
        .and(have_link("$400.00"))
    end

    it "deselects the subcategory when escape is pressed after the assignment closes" do
      find("a", text: "$400.00").click
      find("input[inputmode='decimal']").send_keys(:escape)

      wait_for(have_link("$400.00").and(have_css("tr[data-selected]", text: first_subcategory.name))) do
        find("body").send_keys(:escape)
      end

      expect(page).to have_no_css("tr[data-selected]")
        .and(have_css("[data-selection-target='summary']", text: t("budgets.show.rollover")))
    end

    it "deselects every subcategory when escape is pressed during a multiple selection" do
      check(first_subcategory.name)

      wait_for(have_css("#category_panel", text: first_subcategory.name)) do
        check(second_subcategory.name)
      end

      wait_for(have_css("#category_panel", text: t("categories.summary.title", count: 2))) do
        find("body").send_keys(:escape)
      end

      expect(page).to have_unchecked_field(first_subcategory.name)
        .and(have_unchecked_field(second_subcategory.name))
        .and(have_no_css("tr[data-selected]"))
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

    it "shows the selection summary and keeps both checked when a second is selected" do
      check(first_subcategory.name)

      wait_for(have_css("#category_panel", text: first_subcategory.name)) do
        check(second_subcategory.name)
      end

      expect(page).to have_css("#category_panel", text: t("categories.summary.title", count: 2))
        .and(have_checked_field(first_subcategory.name))
        .and(have_checked_field(second_subcategory.name))
    end

    it "returns to the single subcategory detail when the selection drops to one" do
      check(first_subcategory.name)
      check(second_subcategory.name)

      wait_for(have_css("#category_panel", text: t("categories.summary.title", count: 2))) do
        uncheck(second_subcategory.name)
      end

      expect(page).to have_css("#category_panel", text: first_subcategory.name)
        .and(have_no_css("#category_panel", text: t("categories.summary.title", count: 2)))
    end

    it "restores the month summary when the subcategory is deselected" do
      check(first_subcategory.name)

      wait_for(have_css("#category_panel", text: first_subcategory.name)) do
        uncheck(first_subcategory.name)
      end

      expect(page).to have_css("turbo-frame#category_panel.hidden", visible: :all)
        .and(have_css("[data-selection-target='summary']", text: t("budgets.show.rollover")))
    end

    it "checks its subcategories and shows the summary when the category is checked" do
      check(category.name)

      expect(page).to have_checked_field(first_subcategory.name)
        .and(have_checked_field(second_subcategory.name))
        .and(have_css("#category_panel", text: t("categories.summary.title", count: 2)))
    end

    it "checks every subcategory and shows the summary when select all is checked" do
      check(t("budgets.show.select_all"))

      expect(page).to have_checked_field(first_subcategory.name)
        .and(have_checked_field(second_subcategory.name))
        .and(have_css("#category_panel", text: t("categories.summary.title", count: 2)))
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

    it "does not render a selection checkbox for each category" do
      category = create(:category)
      budget   = category.budget

      sign_in_for(budget)
      visit budget_path(budget)

      expect(page).to have_text(category.name).and(have_no_field(category.name, type: :checkbox))
    end
  end
end
