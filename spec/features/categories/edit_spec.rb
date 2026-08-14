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
    describe "renaming from the subcategory name" do
      before do
        check(subcategory.name)

        wait_for(have_css("tr[data-selected]", text: subcategory.name)) do
          within("tr[data-selected]") do
            find("span", text: subcategory.name).click
          end
        end
      end

      it "opens a popover pre-filled with the current name and no modal" do
        expect(page).to have_field("category_form_name", with: subcategory.name)
          .and(have_no_css("#category_rename_dialog_modal", visible: :all))
      end

      it "renames the category and refreshes the row and panel" do
        fill_in "category_form_name", with: "Renamed Subcategory"
        click_on t("categories.edit.submit")

        expect(page).to have_css("tr[data-selected]", text: "Renamed Subcategory")
          .and(have_css("#category_panel", text: "Renamed Subcategory"))
      end

      it "closes the popover when cancelling" do
        click_on t("categories.edit.cancel")

        expect(page).to have_no_field("category_form_name")
      end

      it "closes the popover when pressing escape" do
        find_field("category_form_name").send_keys(:escape)

        expect(page).to have_no_field("category_form_name")
      end

      it "closes the popover when clicking outside it" do
        find("h1").click

        expect(page).to have_no_field("category_form_name")
      end

      it "keeps the popover open and shows an error for a reserved name" do
        fill_in "category_form_name", with: Category::INFLOW
        click_on t("categories.edit.submit")

        expect(page).to have_text(
          t("activemodel.errors.models.category_form.attributes.name.reserved")
        ).and(have_field("category_form_name"))
      end
    end

    describe "renaming from the sidebar panel" do
      before do
        check(subcategory.name)

        wait_for(have_css("#category_panel", text: subcategory.name)) do
          within("#category_panel") do
            find("button[aria-label='#{t("categories.show.rename")}']").click
          end
        end
      end

      it "opens a popover pre-filled with the current name" do
        within "#category_panel" do
          expect(page).to have_field("category_form_name", with: subcategory.name)
        end
      end

      it "renames the category and refreshes the row and panel" do
        within "#category_panel" do
          fill_in "category_form_name", with: "Renamed Subcategory"
          click_on t("categories.edit.submit")
        end

        expect(page).to have_css("tr[data-selected]", text: "Renamed Subcategory")
          .and(have_css("#category_panel", text: "Renamed Subcategory"))
      end

      it "closes the popover when cancelling" do
        within "#category_panel" do
          click_on t("categories.edit.cancel")
        end

        expect(page).to have_no_field("category_form_name")
          .and(have_css("#category_panel h2", text: subcategory.name))
      end
    end

    it "does not open the popover for an unselected subcategory name" do
      within("tr", text: subcategory.name) do
        find("span", text: subcategory.name).click
      end

      expect(page).to have_no_field("category_form_name")
        .and(have_css("tr[data-selected]", text: subcategory.name))
    end

    it "keeps the subcategory selected when escape dismisses the popover" do
      check(subcategory.name)

      wait_for(have_css("tr[data-selected]", text: subcategory.name)) do
        within("tr[data-selected]") do
          find("span", text: subcategory.name).click
        end
      end

      find_field("category_form_name").send_keys(:escape)

      expect(page).to have_no_field("category_form_name")
        .and(have_css("tr[data-selected]", text: subcategory.name))
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
