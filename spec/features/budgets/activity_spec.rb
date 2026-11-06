# frozen_string_literal: true

require "rails_helper"

describe "Budget activity", :js do
  let(:activity)    { "-$12.50" }
  let(:budget)      { create(:budget) }
  let(:payee)       { create(:payee, budget: budget, name: "Corner Store") }
  let(:subcategory) { create(:category, :subcategory, budget: budget, name: "Groceries", with_snapshot: false) }

  before do
    CreateTransaction.call(
      transaction: create(:transaction, amount:      -1250,
                                        budget:      budget,
                                        payee:       payee,
                                        subcategory: subcategory)
    )

    sign_in_for(budget)
    visit budget_path(budget)
  end

  context "when the amount is clicked" do
    before do
      click_link activity

      find("td", text: payee.name, match: :first)
    end

    it "lists the transactions for the month" do
      expect(page).to have_text(payee.name)
    end

    it "closes the list when clicking the amount again" do
      click_link activity

      expect(page).to have_no_text(payee.name)
    end

    it "closes the list when clicking elsewhere" do
      find_by_id("available_to_assign").click

      expect(page).to have_no_text(payee.name)
    end
  end
end
