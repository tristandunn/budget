# frozen_string_literal: true

require "rails_helper"

describe "Listing payees", :js do
  let(:budget)    { payee_one.budget }
  let(:payee_one) { create(:payee, budget: payee_two.budget) }
  let(:payee_two) { create(:payee) }

  before do
    visit budget_path(budget)
  end

  it "navigates from the budget menu to the payees list" do
    find("button[aria-label='#{t("budgets.show.menu")}']").click
    click_on t("budgets.show.manage_payees")

    expect(page).to have_text(payee_one.name).and(have_text(payee_two.name))
  end
end
