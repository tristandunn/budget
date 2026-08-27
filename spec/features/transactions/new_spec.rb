# frozen_string_literal: true

require "rails_helper"

describe "Transaction" do
  let(:account)     { create(:account) }
  let(:budget)      { account.budget }
  let(:subcategory) { create(:category, :subcategory, budget: budget) }

  before do
    budget.update!(available_to_assign: 10_000)
    subcategory.snapshots.first.update!(amount_assigned: 10_000, amount_used: 0)

    sign_in_for(budget)

    visit budget_account_transactions_path(budget, account)
    click_on "add-transaction"
  end

  it "creates a transaction" do
    fill_in_transaction_and_submit(account: account, amount: -13.37, subcategory: subcategory)

    expect(page).to have_text("Test Payee").and(have_text("$13.37"))
  end

  it "closes an open picker on escape without discarding the form", :js do
    fill_in t("transactions.form.enter_memo"), with: "Groceries"

    find("[data-payee-picker-target='display']").click

    search = find("input[data-payee-picker-target='search']")
    search.send_keys("Test")
    search.send_keys(:escape)

    expect(page).to have_no_css("input[data-payee-picker-target='search']")
      .and(have_field(t("transactions.form.enter_memo"), with: "Groceries"))
  end

  it "closes an open picker on a close request without discarding the form", :js do
    fill_in t("transactions.form.enter_memo"), with: "Groceries"

    find("[data-payee-picker-target='display']").click

    find_by_id("transaction_dialog_modal").execute_script("this.requestClose()")

    expect(page).to have_no_css("input[data-payee-picker-target='search']")
      .and(have_field(t("transactions.form.enter_memo"), with: "Groceries"))
  end

  it "displays a scheduled recurring transaction", :js do
    fill_in t("activemodel.attributes.transaction_form.date"), with: 1.month.from_now.to_date.to_s
    fill_in_frequency(:monthly)
    fill_in_transaction_and_submit(account: account, subcategory: subcategory)

    expect(page).to have_text(t("transactions.list.scheduled")).and(have_text("Test Payee"))
  end

  it "posts a recurring transaction with a new payee" do
    fill_in_frequency(:monthly)
    fill_in_transaction_and_submit(account: account, subcategory: subcategory)

    expect(page).to have_text(t("transactions.list.scheduled"))
      .and(have_text("Test Payee"))
      .and(have_text("$100.00"))
  end

  protected

  # Fill in the new transaction form with a test payee and submit it.
  #
  # @param account [Account] The account to select.
  # @param subcategory [Category] The subcategory to select.
  # @param amount [Integer] The amount to enter.
  # @return [void]
  def fill_in_transaction_and_submit(account:, subcategory:, amount: -100)
    fill_in t("activemodel.attributes.transaction_form.amount"), with: amount
    fill_in_payee("Test Payee")
    fill_in_category(subcategory)
    fill_in_account(account)
    click_on t("transactions.new.submit")
  end
end
