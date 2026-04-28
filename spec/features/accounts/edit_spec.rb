# frozen_string_literal: true

require "rails_helper"

describe "Account editing", :js do
  let(:account) { create(:account, budget: budget, name: "Old Name") }
  let(:budget)  { create(:budget) }

  before do
    visit budget_account_transactions_path(budget, account)
    find("button[aria-label='#{t("transactions.index.actions")}']").click
    click_on t("accounts.transactions.actions.edit")
  end

  it "renames the account" do
    fill_in AccountForm.human_attribute_name(:name), with: "New Name"
    click_on t("accounts.edit.submit")

    expect(page).to have_content("New Name").and(have_no_content("Old Name"))
  end

  it "keeps the dialog open after a validation error" do
    other_account = create(:account, budget: budget)

    fill_in AccountForm.human_attribute_name(:name), with: other_account.name
    click_on t("accounts.edit.submit")

    expect(page).to have_css("dialog[open] turbo-frame#account_dialog", visible: :all)
  end
end
