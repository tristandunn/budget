# frozen_string_literal: true

require "rails_helper"

describe "Listing payees", :js do
  let(:budget)     { create(:budget) }
  let!(:payee_one) { create(:payee, budget: budget) }
  let!(:payee_two) { create(:payee, budget: budget) }

  before do
    sign_in_for(budget)
    visit budget_path(budget)
  end

  it "navigates from the sidebar to the payees list" do
    find("button[aria-label='#{t("budgets.show.menu")}']").click
    click_on t("budgets.show.manage_payees")

    expect(page).to have_text(payee_one.name).and(have_text(payee_two.name))
  end

  context "when on a mobile browser", :mobile do
    it "navigates from the budget menu to the payees list" do
      find("button[aria-label='#{t("budgets.show.menu")}']").click
      click_on t("budgets.show.manage_payees")

      expect(page).to have_text(payee_one.name).and(have_text(payee_two.name))
    end
  end
end
