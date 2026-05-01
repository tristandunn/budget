# frozen_string_literal: true

require "rails_helper"

describe "Transfer deletion", :js do
  let(:budget)   { create(:budget) }
  let(:checking) { create(:account, balance: 50_000, budget: budget) }
  let(:pair)     { create(:transaction, budget: budget, account: savings) }
  let(:payee)    { create(:payee, budget: budget) }
  let(:savings)  { create(:account, balance: 20_000, budget: budget) }

  before do
    create(:transaction, budget: budget, account: checking, payee: payee, transfer_pair: pair)

    visit budget_transactions_path(budget)
    click_on payee.name
  end

  it "deletes the transfer" do
    accept_confirm do
      click_on t("transfers.show.delete.submit")
    end

    expect(page)
      .to have_text(t("transactions.index.title"))
      .and(have_no_text(payee.name))
      .and(have_no_text(pair.payee.name))
  end
end
