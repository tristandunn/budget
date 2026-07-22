# frozen_string_literal: true

require "rails_helper"

describe "Budget editing" do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
    visit budget_path(budget)
  end

  context "when on a desktop browser", :js do
    before do
      find("button[aria-label='#{t("budgets.show.menu")}']").click
      find_by_id("edit-budget").click
    end

    it "renames the budget and updates the sidebar" do
      within "#budget_settings_dialog_modal" do
        fill_in "budget_name", with: "New Name"
        click_on t("budgets.edit.submit")
      end

      expect(page).to have_no_css("#budget_settings_dialog_modal[open]")
        .and(have_css("#budget_title", text: "New Name"))
    end

    it "updates the time zone" do
      within "#budget_settings_dialog_modal" do
        select "(GMT-05:00) Eastern Time (US & Canada)", from: "budget_time_zone"
        click_on t("budgets.edit.submit")
      end

      page.assert_no_selector("#budget_settings_dialog_modal[open]")

      find("button[aria-label='#{t("budgets.show.menu")}']").click
      find_by_id("edit-budget").click

      within "#budget_settings_dialog_modal" do
        expect(page).to have_select("budget_time_zone", selected: "(GMT-05:00) Eastern Time (US & Canada)")
      end
    end

    it "shows an error and keeps the window open when the name is invalid" do
      within "#budget_settings_dialog_modal" do
        fill_in "budget_name", with: "   "
        click_on t("budgets.edit.submit")
      end

      expect(page).to have_css("#budget_settings_dialog_modal[open]", text: t("errors.messages.blank"))
        .and(have_css("#budget_title", text: budget.name))
    end

    it "dismisses the window on escape" do
      find_by_id("budget_settings_dialog_modal").send_keys(:escape)

      expect(page).to have_no_css("#budget_settings_dialog_modal[open]")
    end
  end
end
