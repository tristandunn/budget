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
        within("#category_panel") { click_on t("categories.show.target.desktop.edit") }
      end
    end

    it "edits the target amount inline and refreshes the panel" do
      within "#category_panel" do
        fill_in t("activemodel.attributes.target_form.target_amount_input"), with: "350.00"
        click_on t("targets.edit.submit")

        expect(page).to have_text("$350.00")
      end
    end

    it "persists a change to the target type" do
      within "#category_panel" do
        choose t("targets.edit.set_aside_option"), allow_label_click: true
        click_on t("targets.edit.submit")

        expect(page).to have_text(t("categories.show.target.monthly_savings_label"))
      end
    end

    it "restores the display without saving when cancelling" do
      within "#category_panel" do
        fill_in t("activemodel.attributes.target_form.target_amount_input"), with: "999.00"
        click_on t("targets.edit.cancel")

        expect(page).to have_link(t("categories.show.target.desktop.edit"))
          .and(have_text("$200.00"))
          .and(have_no_field(t("activemodel.attributes.target_form.target_amount_input")))
      end
    end

    it "dismisses the edit and keeps the subcategory selected on escape" do
      within("#category_panel") do
        find_field(t("activemodel.attributes.target_form.target_amount_input")).send_keys(:escape)
      end

      expect(page).to have_css("tr[data-selected]", text: subcategory.name)
        .and(have_link(t("categories.show.target.desktop.edit")))
        .and(have_no_field(t("activemodel.attributes.target_form.target_amount_input")))
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
