# frozen_string_literal: true

require "rails_helper"

describe "Transaction clearing", :js do
  let(:account) { create(:account) }
  let(:budget)  { account.budget }

  let(:transaction) do
    create(:transaction, budget:  budget,
                         account: account,
                         amount:  -1000,
                         status:  status)
  end

  before do
    CreateTransaction.call(transaction: transaction)

    sign_in_for(budget)

    visit budget_transactions_path(budget)
  end

  context "when the transaction is pending" do
    let(:status) { :pending }

    it "clears the transaction" do
      click_button t("transactions.status_indicator.pending")

      expect(page).to have_button(t("transactions.status_indicator.cleared"))
    end
  end

  context "when the transaction is cleared" do
    let(:status) { :cleared }

    it "unclears the transaction" do
      click_button t("transactions.status_indicator.cleared")

      expect(page).to have_button(t("transactions.status_indicator.pending"))
    end
  end

  context "when the transaction is reconciled" do
    let(:status) { :reconciled }

    it "shows the reconciled indicator" do
      expect(page).to have_css("[aria-label='#{t("transactions.status_indicator.reconciled")}']")
    end

    it "does not show a clear button" do
      expect(page).to have_text(transaction.payee.name)
        .and(have_no_button(t("transactions.status_indicator.pending")))
        .and(have_no_button(t("transactions.status_indicator.cleared")))
    end
  end
end
