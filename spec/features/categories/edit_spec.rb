# frozen_string_literal: true

require "rails_helper"

describe "Category editing" do
  let(:budget)      { subcategory.budget }
  let(:subcategory) { create(:category, :subcategory) }

  before do
    sign_in_for(budget)
    visit budget_path(budget)
  end

  context "when on a desktop browser", :js do
    before do
      check(subcategory.name)

      wait_for(have_css("#category_panel", text: subcategory.name)) do
        within("#category_panel") do
          find("a[aria-label='#{t("categories.show.rename")}']").click
        end
      end
    end

    it "updates the category name and refreshes the row and panel" do
      within "#category_rename_dialog_modal" do
        fill_in "category_form_name", with: "Renamed Subcategory"
        click_on t("categories.edit.submit")
      end

      expect(page).to have_css("tr[data-selected]", text: "Renamed Subcategory")
        .and(have_css("#category_panel", text: "Renamed Subcategory"))
    end
  end

  context "when on a mobile browser", :mobile do
    before do
      click_on subcategory.name
      click_on t("categories.show.rename")
    end

    it "updates the category name" do
      fill_in "category_form_name", with: "New Name"
      click_on t("categories.edit.submit")

      expect(page).to have_text("New Name")
    end

    it "does not allow renaming to a reserved inflow name" do
      fill_in "category_form_name", with: Category::INFLOW
      click_on t("categories.edit.submit")

      expect(page).to have_text(
        t("activemodel.errors.models.category_form.attributes.name.reserved")
      )
    end
  end
end
