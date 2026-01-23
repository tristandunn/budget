# frozen_string_literal: true

require "rails_helper"

describe "Budget" do
  context "with a budget" do
    it "renders the current month and year" do
      create(:budget)

      visit "/"

      expect(page).to have_content(Date.current.strftime("%B %Y"))
    end

    it "renders the parent categories" do
      category = create(:category)

      visit "/"

      expect(page).to have_content(category.name)
    end

    it "renders the subcategories" do
      subcategory = create(:category, :subcategory)

      visit "/"

      expect(page).to have_content(subcategory.name)
    end
  end
end
