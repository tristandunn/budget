# frozen_string_literal: true

require "rails_helper"

describe "Transfer" do
  let(:budget)   { create(:budget) }
  let(:checking) { create(:account, balance: 50_000, budget: budget) }
  let(:savings)  { create(:account, balance: 20_000, budget: budget) }

  before do
    checking
    savings

    visit new_budget_transfer_path(budget)
  end

  it "creates a transfer between accounts" do
    fill_in_from_account(checking)
    fill_in_to_account(savings)
    fill_in TransferForm.human_attribute_name(:amount), with: "50.00"
    click_on t("transfers.new.submit")

    expect(page).to have_css("li", text: "#{t("transfers.payee.from", account: checking.name)} $50.00")
  end

  it "shows an inline error when the form is invalid" do
    fill_in TransferForm.human_attribute_name(:amount), with: "0"
    click_on t("transfers.new.submit")

    expect(page).to have_content(
      "#{TransferForm.human_attribute_name(:amount)} " \
      "#{t("errors.messages.greater_than", count: 0)}"
    )
  end

  context "with a to_account_id in the URL" do
    before do
      visit new_budget_transfer_path(budget, to_account_id: savings.id)
    end

    it "pre-selects the matching account in the to-account picker" do
      within("[data-controller~='to-account-picker']") do
        expect(page).to have_css("[role='option'][aria-selected='true']", text: savings.name)
      end
    end
  end

  context "when clicking a transfer row" do
    let(:pair)  { create(:transaction, budget: budget, account: savings) }
    let(:payee) { create(:payee, budget: budget, name: "Transfer to Savings") }

    before do
      create(:transaction, budget: budget, account: checking, payee: payee, transfer_pair: pair)

      visit budget_transactions_path(budget)
      click_on payee.name
    end

    it "opens a read-only dialog" do
      within("turbo-frame#transaction_dialog") do
        expect(page).to have_no_css("input:not([type='hidden']), select, textarea")
      end
    end
  end
end
