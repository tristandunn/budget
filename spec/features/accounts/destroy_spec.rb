# frozen_string_literal: true

require "rails_helper"

describe "Account deletion", :js do
  let(:account) { create(:account, budget: budget) }
  let(:budget)  { create(:budget) }

  before do
    visit budget_account_transactions_path(budget, account)
    find("button[aria-label='#{t("transactions.index.actions")}']").click
    click_on t("accounts.transactions.actions.edit")
  end

  it "deletes the account" do
    accept_confirm do
      click_on t("accounts.form.delete")
    end

    expect(page).to have_no_text(account.name)
  end
end
