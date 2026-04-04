# frozen_string_literal: true

require "rails_helper"

describe "Hiding reconciled transactions", :js do
  let(:account) { create(:account, budget: budget) }
  let(:budget)  { create(:budget) }

  before do
    create(:transaction, :reconciled, budget: budget, account: account, payee: "Reconciled Payment")
    create(:transaction, budget: budget, account: account, payee: "Pending Payment")

    visit budget_transactions_path(budget)
    find("button[aria-label='#{t("transactions.index.actions")}']").click
    click_on t("transactions.reconciled.hide")
  end

  it "hides reconciled transactions" do
    expect(page).to have_text("Pending Payment")
      .and(have_no_text("Reconciled Payment"))
  end

  it "shows reconciled transactions after unhiding" do
    wait_for(have_no_text("Reconciled Payment")) do
      find("button[aria-label='#{t("transactions.index.actions")}']").click
      click_on t("transactions.reconciled.show")
    end

    expect(page).to have_text("Reconciled Payment")
  end
end
