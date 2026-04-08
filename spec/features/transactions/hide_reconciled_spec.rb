# frozen_string_literal: true

require "rails_helper"

describe "Hiding reconciled transactions", :js do
  let(:account)      { create(:account, budget: budget) }
  let(:budget)       { create(:budget) }
  let(:reconciled)   { create(:transaction, :reconciled, budget: budget, account: account) }
  let(:unreconciled) { create(:transaction, budget: budget, account: account) }

  before do
    visit budget_transactions_path(budget)
    find("button[aria-label='#{t("transactions.index.actions")}']").click
    click_on t("transactions.reconciled.hide")
  end

  it "hides reconciled transactions" do
    expect(page).to have_text(unreconciled.payee.name)
      .and(have_no_text(reconciled.payee.name))
  end

  it "shows reconciled transactions after unhiding" do
    wait_for(have_no_text(reconciled.payee.name)) do
      find("button[aria-label='#{t("transactions.index.actions")}']").click
      click_on t("transactions.reconciled.show")
    end

    expect(page).to have_text(reconciled.payee.name)
  end
end
