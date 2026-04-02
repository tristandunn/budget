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
      .and(have_text(transaction.payee))
  end
end
