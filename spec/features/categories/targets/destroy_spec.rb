# frozen_string_literal: true

require "rails_helper"

describe "Category target deletion" do
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

    it "deletes the target inline and returns to the prompt" do
      within "#category_panel" do
        accept_confirm(t("targets.edit.delete_confirmation")) do
          click_on t("targets.edit.desktop.delete")
        end

        expect(page).to have_link(t("categories.show.target.desktop.create"))
      end
    end
  end

  context "when on a mobile browser", :mobile do
    before do
      click_on subcategory.name
      click_on t("categories.show.target.edit")
    end

    it "deletes the target" do
      click_on t("targets.edit.delete")
      click_on subcategory.name

      expect(page).to have_link(t("categories.show.target.create"))
    end
  end
end
