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
      click_button "Pending"

      expect(page).to have_button("Cleared")
    end
  end

  context "when the transaction is cleared" do
    let(:status) { :cleared }

    it "unclears the transaction" do
      click_button "Cleared"

      expect(page).to have_button("Pending")
    end
  end

  context "when the transaction is reconciled" do
    let(:status) { :reconciled }

    it "does not show a clear button" do
      expect(page).to have_css("[aria-label='Reconciled']")
    end
  end
end
