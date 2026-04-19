# frozen_string_literal: true

require "rails_helper"

describe "Transaction" do
  let(:account)     { create(:account) }
  let(:budget)      { account.budget }
  let(:subcategory) { create(:category, :subcategory, budget: budget) }

  before do
    budget.update!(available_to_assign: 10_000)
    subcategory.snapshots.first.update!(amount_assigned: 10_000, amount_used: 0)

    visit budget_account_transactions_path(budget, account)
    click_on "add-transaction"
  end

  it "creates a transaction" do
    fill_in_transaction_and_submit(account: account, amount: -13.37, subcategory: subcategory)

    expect(page).to have_text("Test Payee").and(have_text("$13.37"))
  end

  it "displays a scheduled recurring transaction", :js do
    fill_in t("activemodel.attributes.transaction_form.date"), with: 1.month.from_now.to_date.to_s
    select "Monthly", from: t("activemodel.attributes.transaction_form.frequency")
    fill_in_transaction_and_submit(account: account, subcategory: subcategory)

    expect(page).to have_text(t("transactions.list.scheduled")).and(have_text("Test Payee"))
  end

  protected

  def fill_in_transaction_and_submit(account:, subcategory:, amount: -100)
    fill_in t("activemodel.attributes.transaction_form.amount"), with: amount
    fill_in_payee("Test Payee")
    fill_in_category(subcategory)
    select account.name, from: t("activemodel.attributes.transaction_form.account_id")
    click_on t("transactions.new.submit")
  end
end
