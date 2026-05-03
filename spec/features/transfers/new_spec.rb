# frozen_string_literal: true

require "rails_helper"

describe "Transfer" do
  let(:budget)      { create(:budget) }
  let(:checking)    { create(:account, balance: 50_000, budget: budget) }
  let(:credit_card) { create(:account, :credit, balance: 20_000, budget: budget) }

  before do
    checking
    credit_card

    visit new_budget_transfer_path(budget)
  end

  it "creates a transfer between accounts" do
    fill_in_from_account(checking)
    fill_in_to_account(credit_card)
    fill_in TransferForm.human_attribute_name(:amount), with: "50.00"
    click_on t("transfers.new.submit")

    expect(page).to have_css("li", text: "#{t("transfers.payee.from", account: checking.name)} $50.00")
  end

  context "with a to_account_id in the URL" do
    before do
      visit new_budget_transfer_path(budget, to_account_id: credit_card.id)
    end

    it "pre-selects the matching account in the to-account picker" do
      within("[data-controller~='to-account-picker']") do
        expect(page).to have_css("[role='option'][aria-selected='true']", text: credit_card.name)
      end
    end
  end

  context "when clicking a transfer row" do
    before do
      CreateTransfer.call(
        accounts: { from: checking, to: credit_card },
        amount:   Money.from_amount(50),
        budget:   budget,
        date:     Date.current
      )

      visit budget_transactions_path(budget)
      click_on t("transfers.payee.to", account: credit_card.name)
    end

    it "opens a read-only dialog" do
      within("turbo-frame#transaction_dialog") do
        expect(page).to have_no_css("input:not([type='hidden']), select, textarea")
      end
    end
  end
end
