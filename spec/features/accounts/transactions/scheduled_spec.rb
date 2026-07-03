# frozen_string_literal: true

require "rails_helper"

describe "Collapsing scheduled account transactions", :js do
  let(:budget)   { create(:budget) }
  let(:checking) { create(:account, budget: budget) }
  let(:savings)  { create(:account, budget: budget) }

  let!(:checking_transaction) { create(:transaction, :recurring, budget: budget, account: checking) }
  let!(:savings_transaction)  { create(:transaction, :recurring, budget: budget, account: savings) }

  before do
    sign_in_for(budget)

    visit budget_account_transactions_path(budget, checking)
  end

  it "hides scheduled transactions when clicking the header" do
    find("th[scope='rowgroup']", text: t("transactions.list.scheduled")).click

    expect(page).to have_no_text(checking_transaction.payee.name)
  end

  it "shows scheduled transactions when clicking a collapsed header" do
    2.times { find("th[scope='rowgroup']", text: t("transactions.list.scheduled")).click }

    expect(page).to have_text(checking_transaction.payee.name)
  end

  it "does not collapse the scheduled transactions for another account" do
    find("th[scope='rowgroup']", text: t("transactions.list.scheduled")).click

    visit budget_account_transactions_path(budget, savings)

    expect(page).to have_text(savings_transaction.payee.name)
  end

  it "does not collapse the scheduled transactions on the all-accounts index" do
    find("th[scope='rowgroup']", text: t("transactions.list.scheduled")).click

    visit budget_transactions_path(budget)

    expect(page).to have_text(checking_transaction.payee.name)
  end

  it "remembers the collapsed state after reloading" do
    find("th[scope='rowgroup']", text: t("transactions.list.scheduled")).click

    visit budget_account_transactions_path(budget, checking)

    expect(page).to have_text(t("transactions.list.scheduled"))
      .and(have_no_text(checking_transaction.payee.name))
  end

  context "when on a mobile browser", :mobile do
    it "does not collapse the scheduled transactions for another account" do
      find("h3", text: t("transactions.list.scheduled")).click

      visit budget_account_transactions_path(budget, savings)

      expect(page).to have_text(savings_transaction.payee.name)
    end
  end
end
