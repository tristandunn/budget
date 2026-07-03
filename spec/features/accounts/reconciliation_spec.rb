# frozen_string_literal: true

require "rails_helper"

describe "Account reconciliation", :js do
  let(:account) { create(:account, balance: -5000) }
  let(:budget)  { account.budget }

  before do
    sign_in_for(budget)
  end

  context "when the account has a cleared transaction" do
    before do
      create(:transaction, :cleared, budget: budget, account: account, amount: -5000)

      visit budget_account_transactions_path(budget, account)
    end

    it "reveals the cleared balance in an inline panel" do
      click_on t("accounts.transactions.reconcile.reconcile"), exact: true

      within "[data-confirm-target='panel']" do
        expect(page).to have_text("-$50.00")
      end
    end

    it "reconciles cleared transactions after confirming" do
      click_on t("accounts.transactions.reconcile.reconcile"), exact: true

      within "[data-confirm-target='panel']" do
        click_on t("accounts.transactions.reconcile.accept")
      end

      expect(page).to have_css("[aria-label='#{t("transactions.status_indicator.reconciled")}']")
    end

    it "does not reconcile when declined" do
      click_on t("accounts.transactions.reconcile.reconcile"), exact: true
      click_on t("accounts.transactions.reconcile.decline")

      expect(page)
        .to have_no_button(t("accounts.transactions.reconcile.accept"))
        .and have_no_css("[aria-label='#{t("transactions.status_indicator.reconciled")}']")
    end

    it "dismisses the inline panel when clicking outside" do
      click_on t("accounts.transactions.reconcile.reconcile"), exact: true

      wait_for(have_button(t("accounts.transactions.reconcile.accept"))) do
        find("h1", text: account.name).click
      end

      expect(page).to have_no_button(t("accounts.transactions.reconcile.accept"))
    end

    context "when on a mobile device", :mobile do
      it "reconciles from the actions menu" do
        find("button[aria-label='#{t("transactions.index.actions")}']").click

        find("button[data-action='click->confirm#prompt']").click

        within "[data-confirm-target='panel']" do
          click_on t("accounts.transactions.reconcile.accept")
        end

        expect(page).to have_css("[aria-label='#{t("transactions.status_indicator.reconciled")}']")
      end
    end
  end

  context "when the account has no transactions to reconcile", :mobile do
    before do
      visit budget_account_transactions_path(budget, account)
    end

    it "shows reconciliation option in the actions menu" do
      find("button[aria-label='#{t("transactions.index.actions")}']").click

      expect(page).to have_button(t("accounts.transactions.reconcile.reconcile"))
    end
  end

  context "when clearing and unclearing transactions" do
    before do
      create(:transaction, budget: budget, account: account, amount: -1000)

      visit budget_account_transactions_path(budget, account)
    end

    it "reveals the reconcile button after clearing a transaction" do
      click_button t("transactions.status_indicator.pending")

      expect(page).to have_button(t("accounts.transactions.reconcile.reconcile"), exact: true)
    end

    it "hides the reconcile button after unclearing the last cleared transaction" do
      click_button t("transactions.status_indicator.pending")

      wait_for(have_button(t("accounts.transactions.reconcile.reconcile"), exact: true)) do
        click_button t("transactions.status_indicator.cleared")
      end

      expect(page).to have_no_button(t("accounts.transactions.reconcile.reconcile"), exact: true)
    end
  end
end
