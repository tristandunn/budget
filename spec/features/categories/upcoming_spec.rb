# frozen_string_literal: true

require "rails_helper"

describe "Category upcoming transactions", :js do
  let(:budget)   { create(:budget) }
  let(:category) { create(:category, budget: budget) }

  let(:subcategory) do
    create(:category, :subcategory, budget: budget, parent: category, with_snapshot: false)
  end

  before do
    create(:category_snapshot, budget:          budget,
                               category:        subcategory,
                               amount_assigned: 40_000,
                               amount_used:     10_000)

    sign_in_for(budget)
  end

  context "with upcoming transactions in the displayed month" do
    before do
      create(:transaction, :upcoming, budget:      budget,
                                      subcategory: subcategory,
                                      amount:      -3_000,
                                      date:        Date.current.beginning_of_month)
      create(:transaction, :upcoming, budget:      budget,
                                      subcategory: subcategory,
                                      amount:      -2_000,
                                      date:        Date.current.end_of_month)

      visit budget_path(budget)
    end

    it "summarizes them and the available amount after them" do
      check(subcategory.name)

      within("#category_panel") do
        expect(page).to have_text(t("categories.show.upcoming", count: 2))
          .and(have_text("-$50.00"))
          .and(have_text(t("categories.show.available_after_upcoming")))
          .and(have_text("$250.00"))
      end
    end
  end

  context "without upcoming transactions in the displayed month" do
    before do
      visit budget_path(budget)
    end

    it "omits the upcoming summary" do
      check(subcategory.name)

      within("#category_panel") do
        expect(page).to have_text(subcategory.name)
          .and(have_no_text(t("categories.show.available_after_upcoming")))
      end
    end
  end
end
