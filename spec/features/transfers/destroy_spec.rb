# frozen_string_literal: true

require "rails_helper"

describe "Transfer deletion", :js do
  let(:budget)   { create(:budget) }
  let(:checking) { create(:account, balance: 50_000, budget: budget) }
  let(:savings)  { create(:account, balance: 20_000, budget: budget) }

  before do
    CreateTransfer.call(
      accounts: { from: checking, to: savings },
      amount:   Money.from_amount(50),
      budget:   budget,
      date:     Date.current
    )

    sign_in_for(budget)

    visit budget_transactions_path(budget)
    click_on t("transfers.payee.to", account: savings.name)
  end

  it "deletes the transfer" do
    accept_confirm do
      click_on t("transfers.show.delete.submit")
    end

    expect(page)
      .to have_text(t("sidebar.all_accounts"))
      .and(have_no_text(t("transfers.payee.to", account: savings.name)))
      .and(have_no_text(t("transfers.payee.from", account: checking.name)))
  end

  context "when on a mobile browser", :mobile do
    it "deletes the transfer" do
      accept_confirm do
        click_on t("transfers.show.delete.submit")
      end

      expect(page)
        .to have_text(t("transactions.index.title"))
        .and(have_no_text(t("transfers.payee.to", account: savings.name)))
        .and(have_no_text(t("transfers.payee.from", account: checking.name)))
    end
  end
end
