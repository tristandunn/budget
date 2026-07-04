# frozen_string_literal: true

require "rails_helper"

describe "Category target editing" do
  let(:budget)      { subcategory.budget }
  let(:subcategory) { create(:category, :subcategory, :with_monthly_spending_target, name: "Groceries") }

  before do
    sign_in_for(budget)
    visit budget_path(budget)
  end

  context "when on a desktop browser", :js do
    before do
      check(subcategory.name)

      wait_for(have_css("#category_panel", text: subcategory.name)) do
        within("#category_panel") { click_on t("categories.show.target.edit") }
      end
    end

    it "edits the target amount and refreshes the panel" do
      within "#category_target_dialog_modal" do
        fill_in t("activemodel.attributes.target_form.target_amount_input"), with: "350.00"
        click_on t("targets.edit.submit")
      end

      within("#category_panel") do
        expect(page).to have_text("$350.00")
      end
    end
  end

  context "when on a mobile browser", :mobile do
    before do
      click_on subcategory.name
      click_on t("categories.show.target.edit")
    end

    it "edits the target amount" do
      fill_in t("activemodel.attributes.target_form.target_amount_input"), with: "350.00"
      click_on t("targets.edit.submit")

      click_on subcategory.name
      click_on t("categories.show.target.edit")

      expect(page).to have_field(
        t("activemodel.attributes.target_form.target_amount_input"),
        with: "350.00"
      )
    end
  end
end
