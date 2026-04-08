# frozen_string_literal: true

require "rails_helper"

describe "Transaction deletion", :js do
  let(:account)     { create(:account, budget: budget) }
  let(:budget)      { create(:budget) }
  let(:subcategory) { create(:category, :subcategory, budget: budget) }

  let(:transaction) do
    create(:transaction, budget:      budget,
                         account:     account,
                         subcategory: subcategory,
                         amount:      -1000)
  end

  before do
    CreateTransaction.call(transaction: transaction)

    visit budget_transactions_path(budget)
    click_on transaction.payee.name
  end

  it "deletes the transaction" do
    accept_confirm do
      click_on t("transactions.edit.delete.submit")
    end

    expect(page).to have_text(t("transactions.index.title")).and(have_no_text(transaction.payee.name))
  end
end
