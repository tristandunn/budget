# frozen_string_literal: true

require "rails_helper"

describe "Budget" do
  context "with a budget" do
    it "renders the current month and year" do
      budget = create(:budget)

      sign_in_for(budget)
      visit budget_path(budget)

      expect(page).to have_text(I18n.l(Date.current, format: :month_and_year))
    end

    it "renders the available to assign amount" do
      budget = create(:budget, available_to_assign: 100_000)

      sign_in_for(budget)
      visit budget_path(budget)

      expect(page).to have_text("$1,000.00")
    end

    it "renders the parent categories" do
      category = create(:category)
      budget   = category.budget

      sign_in_for(budget)
      visit budget_path(budget)

      expect(page).to have_text(category.name)
    end

    it "renders the subcategories" do
      subcategory = create(:category, :subcategory)
      budget      = subcategory.budget

      sign_in_for(budget)
      visit budget_path(budget)

      expect(page).to have_text(subcategory.name)
    end

    context "when navigating months" do
      it "navigates to the next month" do
        budget = create(:budget)

        sign_in_for(budget)
        visit budget_path(budget)
        click_on "next-month"

        expect(page).to have_text(I18n.l(1.month.from_now.to_date, format: :month_and_year))
      end

      it "navigates back to the previous month" do
        budget = create(:budget)

        sign_in_for(budget)
        visit budget_path(budget)
        click_on "next-month"
        click_on "previous-month"

        expect(page).to have_text(I18n.l(Date.current, format: :month_and_year))
      end

      it "navigates back to the current month when clicking the month and year" do
        budget = create(:budget)

        sign_in_for(budget)
        visit budget_path(budget)
        click_on "next-month"
        click_on I18n.l(1.month.from_now.to_date, format: :month_and_year)

        expect(page).to have_text(I18n.l(Date.current, format: :month_and_year))
      end
    end

    context "when toggling a category", :js do
      let(:budget)      { subcategory.budget }
      let(:category)    { subcategory.parent }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        sign_in_for(budget)
        visit budget_path(budget)
      end

      it "hides subcategories when clicking the collapse arrow" do
        find("[data-collapsible-id-value='category-#{category.id}'] [data-collapsible-arrow]").click

        expect(page).to have_no_text(subcategory.name)
      end

      it "shows subcategories when clicking the arrow of a collapsed category" do
        2.times { find("[data-collapsible-id-value='category-#{category.id}'] [data-collapsible-arrow]").click }

        expect(page).to have_text(subcategory.name)
      end
    end

    context "when toggling a category on a mobile browser", :js, :mobile do
      let(:budget)      { subcategory.budget }
      let(:category)    { subcategory.parent }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        sign_in_for(budget)
        visit budget_path(budget)
      end

      it "hides subcategories when clicking the category" do
        find("thead th", text: category.name).click

        expect(page).to have_no_text(subcategory.name)
      end

      it "shows subcategories when clicking a collapsed category" do
        2.times { find("thead th", text: category.name).click }

        expect(page).to have_text(subcategory.name)
      end
    end
  end
end
