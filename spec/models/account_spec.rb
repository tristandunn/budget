# frozen_string_literal: true

require "rails_helper"

describe Account do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to belong_to(:budget) }
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
  end

  describe "validations" do
    subject { create(:account) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:budget_id).case_insensitive }

    it { is_expected.to validate_numericality_of(:balance).only_integer }
  end

  describe ".cash" do
    it "returns accounts that are not credit accounts" do
      cash_account = create(:account, credit: false)
      create(:account, credit: true)

      expect(described_class.cash).to contain_exactly(cash_account)
    end
  end

  describe ".credit" do
    it "returns accounts that are credit accounts" do
      create(:account, credit: false)
      credit_account = create(:account, credit: true)

      expect(described_class.credit).to contain_exactly(credit_account)
    end
  end

  describe ".default_scope" do
    it "orders accounts by name" do
      bob     = create(:account, name: "Bob")
      charlie = create(:account, budget: bob.budget, name: "Charlie")
      alice   = create(:account, budget: bob.budget, name: "Alice")

      expect(described_class.all).to eq([alice, bob, charlie])
    end
  end

  describe "#last_reconciled_at" do
    let(:account) { create(:account) }

    it "returns the time of the most recent reconciliation" do
      transaction = create(:transaction, :reconciled, account: account, budget: account.budget)

      expect(account.last_reconciled_at).to eq(transaction.updated_at)
    end

    it "returns nil when no transactions have been reconciled" do
      create(:transaction, account: account, budget: account.budget)

      expect(account.last_reconciled_at).to be_nil
    end
  end

  describe "#cleared_balance" do
    it "returns the sum of cleared and reconciled transaction amounts" do
      account = create(:account, balance: -9000)
      create(:transaction, account: account, amount: -2000, budget: account.budget)
      create(:transaction, :cleared, account: account, amount: -4000, budget: account.budget)
      create(:transaction, :reconciled, account: account, amount: -3000, budget: account.budget)

      expect(account.cleared_balance).to eq(-7000)
    end

    it "excludes pending transactions" do
      account = create(:account, balance: -1500)
      create(:transaction, account: account, amount: -1500, budget: account.budget)

      expect(account.cleared_balance).to eq(0)
    end
  end

  describe "#uncleared_balance" do
    it "returns the sum of pending transaction amounts" do
      account = create(:account)
      create(:transaction, account: account, amount: -5000, budget: account.budget)
      create(:transaction, :cleared, account: account, amount: -3000, budget: account.budget)

      expect(account.uncleared_balance).to eq(-5000)
    end
  end
end
