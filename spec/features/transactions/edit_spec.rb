# frozen_string_literal: true

require "rails_helper"

describe "Transaction editing" do
  let(:account)     { create(:account, budget: budget) }
  let(:budget)      { create(:budget) }
  let(:subcategory) { create(:category, :subcategory, budget: budget) }
  let(:traits)      { [] }

  let(:transaction) do
    create(:transaction, *traits,
           budget:      budget,
           account:     account,
           subcategory: subcategory,
           amount:      -1000)
  end

  shared_examples "an editable transaction" do
    before do
      CreateTransaction.call(transaction: transaction)

      visit budget_transactions_path(budget)
      click_on transaction.payee.name
    end

    it "updates the transaction" do
      fill_in t("activemodel.attributes.transaction_form.payee"), with: "New Payee"
      fill_in t("activemodel.attributes.transaction_form.amount"), with: -20.00
      click_on t("transactions.edit.submit")

      expect(page).to have_text("New Payee")
        .and(have_text("$20.00"))
    end
  end

  it_behaves_like "an editable transaction"

  context "when recurring" do
    let(:traits) { [:recurring] }

    it_behaves_like "an editable transaction"
  end
end
