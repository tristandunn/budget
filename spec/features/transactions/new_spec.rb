# frozen_string_literal: true

require "rails_helper"

describe "Transaction" do
  let(:account) { create(:account, budget: budget) }
  let(:budget)  { create(:budget, available_to_assign: 10_000) }

  before do
    visit budget_path(budget)
  end

  it "updates the amount remaining" do
    subcategory = create(:category, :subcategory, budget: budget)
    subcategory.snapshots.first.update!(amount_assigned: 10_000, amount_used: 0)

    fill_in_transaction_and_submit(account: account, amount: -13.37, subcategory: subcategory)

    expect(page).to have_text("$86.63")
  end

  context "with an inflow category" do
    it "updates the available to assign" do
      subcategory = create(:category, :inflow_subcategory, budget: budget)

      fill_in_transaction_and_submit(account: account, amount: 13.37, subcategory: subcategory)

      expect(page).to have_text("$113.37")
    end
  end

  protected

  def fill_in_transaction_and_submit(account:, amount:, subcategory:)
    click_on "add-transaction"
    fill_in t("activemodel.attributes.transaction_form.amount"), with: amount
    fill_in t("activemodel.attributes.transaction_form.payee"), with: "Test Payee"
    select subcategory.name, from: t("activemodel.attributes.transaction_form.subcategory_id")
    select account.name, from: t("activemodel.attributes.transaction_form.account_id")
    click_on t("transactions.new.submit")
  end
end
