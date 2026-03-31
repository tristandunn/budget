# frozen_string_literal: true

require "rails_helper"

describe "Account reconciliation", :js do
  let(:account) { create(:account, balance: -5000, budget: budget) }
  let(:budget)  { create(:budget) }

  before do
    create(:transaction, :cleared, budget: budget, account: account, amount: -5000)

    visit budget_account_transactions_path(budget, account)
  end

  it "hides the reconcile button after confirming" do
    accept_confirm do
      click_on t("accounts.transactions.index.reconcile")
    end

    expect(page).to have_no_button(t("accounts.transactions.index.reconcile"))
  end

  it "keeps the reconcile button when cancelled" do
    dismiss_confirm do
      click_on t("accounts.transactions.index.reconcile")
    end

    expect(page).to have_button(t("accounts.transactions.index.reconcile"))
  end
end
