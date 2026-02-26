# frozen_string_literal: true

require "rails_helper"

describe "Budget" do
  context "with a budget" do
    it "renders the current month and year" do
      budget = create(:budget)

      visit budget_path(budget)

      expect(page).to have_content(Date.current.strftime("%B %Y"))
    end

    it "renders the available to assign amount" do
      budget = create(:budget, available_to_assign: 100_000)

      visit budget_path(budget)

      expect(page).to have_content("$1,000.00")
    end

    it "renders the parent categories" do
      category = create(:category)
      budget   = category.budget

      visit budget_path(budget)

      expect(page).to have_content(category.name)
    end

    it "renders the subcategories" do
      subcategory = create(:category, :subcategory)
      budget      = subcategory.budget

      visit budget_path(budget)

      expect(page).to have_content(subcategory.name)
    end

    context "when assigning to a subcategory", :js do
      let(:budget)      { subcategory.budget }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        budget.update!(available_to_assign: 100_000)
        subcategory.snapshots.update_all(amount_assigned: 0) # rubocop:disable Rails/SkipsModelValidations
        subcategory.parent.snapshots.update_all(amount_assigned: 0) # rubocop:disable Rails/SkipsModelValidations
        visit budget_path(budget)
        find("tbody td a", text: "$0.00").click
        fill_in "assignment_form_amount", with: "250.00"
        find_by_id("assignment_form_amount").native.send_keys(:return)
      end

      it "updates the assigned amount" do
        expect(page).to have_content("$250.00")
      end

      it "updates the available to assign amount" do
        expect(page).to have_content("$750.00")
      end
    end

    context "when toggling a category", :js do
      let(:budget)      { subcategory.budget }
      let(:category)    { subcategory.parent }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        visit budget_path(budget)
      end

      it "hides subcategories when clicking the category" do
        find("thead th", text: category.name).click

        expect(page).to have_no_content(subcategory.name)
      end

      it "shows subcategories when clicking a collapsed category" do
        2.times { find("thead th", text: category.name).click }

        expect(page).to have_content(subcategory.name)
      end
    end
  end
end
