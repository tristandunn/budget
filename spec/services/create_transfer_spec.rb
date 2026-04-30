# frozen_string_literal: true

require "rails_helper"

describe CreateTransfer do
  describe ".call" do
    let(:budget)       { create(:budget) }
    let(:from_account) { create(:account, balance: 50_000, budget: budget, name: "Checking") }
    let(:to_account)   { create(:account, balance: 20_000, budget: budget, name: "Savings") }

    def perform
      described_class.call(
        accounts: { from: from_account, to: to_account },
        amount:   Money.from_amount(50),
        budget:   budget,
        date:     Date.new(2026, 4, 15),
        memo:     "Move savings"
      )
    end

    it "creates an outflow transaction on the source account" do
      perform

      expect(from_account.transactions.pluck(:amount)).to eq([-5000])
    end

    it "creates an inflow transaction on the destination account" do
      perform

      expect(to_account.transactions.pluck(:amount)).to eq([5000])
    end

    it "links the outflow row to the inflow row" do
      perform

      outflow = from_account.transactions.first
      inflow  = to_account.transactions.first

      expect(outflow.reload.transfer_pair_id).to eq(inflow.id)
    end

    it "links the inflow row to the outflow row" do
      perform

      outflow = from_account.transactions.first
      inflow  = to_account.transactions.first

      expect(inflow.reload.transfer_pair_id).to eq(outflow.id)
    end

    it "decrements the source account balance" do
      expect { perform }.to change { from_account.reload.balance }.from(50_000).to(45_000)
    end

    it "increments the destination account balance" do
      expect { perform }.to change { to_account.reload.balance }.from(20_000).to(25_000)
    end

    it "does not change available_to_assign on the budget" do
      expect { perform }.not_to(change { budget.reload.available_to_assign })
    end

    it "does not create or modify any category snapshots" do
      expect { perform }.not_to change(CategorySnapshot, :count).from(0)
    end

    it "uses the i18n payee name on the outflow row" do
      perform

      outflow_payee = from_account.transactions.first.payee.name

      expect(outflow_payee).to eq(I18n.t("transfers.payee.name", account: to_account.name))
    end

    it "uses the i18n payee name on the inflow row" do
      perform

      inflow_payee = to_account.transactions.first.payee.name

      expect(inflow_payee).to eq(I18n.t("transfers.payee.name", account: from_account.name))
    end

    it "persists the supplied date on both rows" do
      perform

      dates = (from_account.transactions + to_account.transactions).map(&:date)

      expect(dates).to all(eq(Date.new(2026, 4, 15)))
    end

    it "persists the supplied memo on both rows" do
      perform

      memos = (from_account.transactions + to_account.transactions).map(&:memo)

      expect(memos).to all(eq("Move savings"))
    end

    it "returns true on success" do
      expect(perform).to be(true)
    end
  end
end
