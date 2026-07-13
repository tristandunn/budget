# frozen_string_literal: true

require "rails_helper"

describe "Category target creation" do
  let(:budget)      { subcategory.budget }
  let(:subcategory) { create(:category, :subcategory, name: "Groceries") }

  before do
    sign_in_for(budget)
    visit budget_path(budget)
  end

  context "when on a desktop browser", :js do
    before do
      check(subcategory.name)

      wait_for(have_css("#category_panel", text: subcategory.name)) do
        within("#category_panel") { click_on t("categories.show.target.desktop.create") }
      end
    end

    it "creates a target inline and renders the funded progress" do
      within "#category_panel" do
        fill_in t("activemodel.attributes.target_form.target_amount_input"), with: "200.00"
        click_on t("targets.edit.submit")

        expect(page).to have_link(t("categories.show.target.desktop.edit"))
          .and(have_text("$200.00"))
      end
    end
  end

  context "when on a mobile browser", :mobile do
    before do
      click_on subcategory.name
      click_on t("categories.show.target.create")
    end

    it "creates a monthly spending target" do
      fill_in t("activemodel.attributes.target_form.target_amount_input"), with: "200.00"
      click_on t("targets.edit.submit")

      click_on subcategory.name

      expect(page).to have_link(t("categories.show.target.edit"))
    end
  end
end
