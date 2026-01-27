# frozen_string_literal: true

require "rails_helper"

describe Account do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to belong_to(:budget) }
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
end
