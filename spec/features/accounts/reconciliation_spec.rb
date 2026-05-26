# frozen_string_literal: true

require "rails_helper"

describe "Account reconciliation", :js do
  let(:account) { create(:account, balance: -5000) }
  let(:budget)  { account.budget }

  before do
    create(:transaction, :cleared, account: account, amount: -5000)

    sign_in_for(budget)
    visit budget_account_transactions_path(budget, account)
    find("button[aria-label='#{t("transactions.index.actions")}']").click
  end

  it "reconciles cleared transactions after confirming" do
    accept_confirm do
      within "form[data-turbo-confirm]" do
        click_on t("accounts.transactions.actions.reconcile")
      end
    end

    expect(page).to have_css("[aria-label='#{t("transactions.status_indicator.reconciled")}']")
  end
end
