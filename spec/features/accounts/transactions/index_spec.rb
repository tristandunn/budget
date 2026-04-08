# frozen_string_literal: true

require "rails_helper"

describe "Account transactions" do
  let(:account) { create(:account, budget: budget) }
  let(:budget)  { create(:budget) }

  it "navigates from accounts index to account register" do
    transaction = create(:transaction, account: account)

    visit budget_accounts_path(budget)
    click_on account.name

    expect(page).to have_css("h1", text: account.name)
      .and(have_text(transaction.payee.name))
  end

  it "defaults the account on the new transaction form" do
    visit budget_account_transactions_path(budget, account)
    click_on "add-transaction"

    expect(page).to have_select(
      t("activemodel.attributes.transaction_form.account_id"),
      selected: account.name
    )
  end
end
