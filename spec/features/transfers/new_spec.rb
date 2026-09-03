# frozen_string_literal: true

require "rails_helper"

describe "Transfer", :mobile do
  let(:budget)       { create(:budget) }
  let!(:checking)    { create(:account, balance: 50_000, budget: budget) }
  let!(:credit_card) { create(:account, :credit, balance: 20_000, budget: budget) }

  before do
    sign_in_for(budget)

    visit new_budget_transfer_path(budget)
  end

  it "creates a transfer between accounts" do
    fill_in_from_account(checking)
    fill_in_to_account(credit_card)
    fill_in TransferForm.human_attribute_name(:amount), with: "50.00"
    click_on t("transfers.new.submit")

    expect(page).to have_css("li", text: "#{t("transfers.payee.from", account: checking.name)} $50.00")
  end

  it "pre-selects the only cash account in the from-account picker" do
    within("[data-controller~='from-account-picker']") do
      expect(page).to have_css("[role='option'][aria-selected='true']", text: checking.name)
    end
  end

  context "with multiple cash accounts" do
    before do
      create(:account, budget: budget, name: "Savings")

      visit new_budget_transfer_path(budget)
    end

    it "does not pre-select a source account" do
      within("[data-controller~='from-account-picker']") do
        expect(page).to have_no_css("[role='option'][aria-selected='true']")
      end
    end
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

  context "with a credit to_account_id that has a balance owed" do
    let(:credit_with_balance) { create(:account, :credit, balance: -7000, budget: budget) }

    before do
      visit new_budget_transfer_path(budget, to_account_id: credit_with_balance.id)
    end

    it "defaults the amount to the cleared balance owed" do
      expect(page).to have_field(TransferForm.human_attribute_name(:amount), with: "70.00")
    end
  end

  context "when using the account pickers in a browser", :js do
    before do
      create(:account, budget: budget, name: "Savings")

      visit budget_account_transactions_path(budget, credit_card)

      find("button[aria-label='#{t("transactions.index.actions")}']").click
      click_on t("accounts.transactions.actions.record_payment")
    end

    it "creates a transfer between the accounts chosen in the pickers" do
      select_in_picker("from-account-picker", "Savings")
      fill_in TransferForm.human_attribute_name(:amount), with: "50.00"
      click_on t("transfers.new.submit")

      within("li", text: t("transfers.payee.from", account: "Savings")) do
        expect(page).to have_text("$50.00")
      end
    end

    it "marks the empty picker and keeps the form when submitting without an account" do
      fill_in TransferForm.human_attribute_name(:amount), with: "50.00"
      click_on t("transfers.new.submit")

      expect(page).to have_css("[data-from-account-picker-target='icon'].text-red-700")
        .and(have_field(TransferForm.human_attribute_name(:amount), with: "$50.00"))
    end

    it "returns to the form when dismissing a picker" do
      open_picker("from-account-picker")

      within "[data-from-account-picker-target='picker']" do
        click_on t("shared.picker.back")
      end

      expect(page).to have_no_css("[data-from-account-picker-target='picker'].open")
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
