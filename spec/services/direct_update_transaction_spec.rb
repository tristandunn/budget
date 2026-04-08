# frozen_string_literal: true

require "rails_helper"

describe DirectUpdateTransaction do
  describe ".call" do
    subject(:update) { described_class.call(attributes: attributes, transaction: transaction) }

    let(:new_account)     { create(:account, budget: subcategory.budget) }
    let(:new_subcategory) { create(:category, :subcategory, budget: subcategory.budget) }
    let(:subcategory)     { create(:category, :subcategory) }

    let(:transaction) do
      create(:transaction, budget: subcategory.budget, subcategory: subcategory, amount: -1000)
    end

    let(:attributes) do
      {
        account:     new_account,
        amount:      -2000,
        date:        Date.new(2026, 5, 1),
        frequency:   "monthly",
        memo:        "New Memo",
        payee:       create(:payee, budget: subcategory.budget),
        subcategory: new_subcategory
      }
    end

    it "updates the account" do
      update

      expect(transaction.reload.account).to eq(new_account)
    end

    it "updates the amount" do
      update

      expect(transaction.reload.amount).to eq(-2000)
    end

    it "updates the date" do
      update

      expect(transaction.reload.date).to eq(Date.new(2026, 5, 1))
    end

    it "updates the frequency" do
      update

      expect(transaction.reload.frequency).to eq("monthly")
    end

    it "updates the memo" do
      update

      expect(transaction.reload.memo).to eq("New Memo")
    end

    it "updates the payee" do
      update

      expect(transaction.reload.payee).to eq(attributes[:payee])
    end

    it "updates the subcategory" do
      update

      expect(transaction.reload.subcategory).to eq(new_subcategory)
    end
  end
end
