# frozen_string_literal: true

require "rails_helper"

describe Payee do
  describe "class" do
    it { is_expected.to be_a(ApplicationRecord) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:budget) }
    it { is_expected.to have_many(:transactions).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject(:payee) { create(:payee) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:budget_id).case_insensitive }
  end

  describe ".by_name" do
    let(:budget) { create(:budget) }
    let(:payee)  { create(:payee, budget: budget) }

    it "matches a name that differs only in case" do
      expect(budget.payees.by_name(payee.name.downcase)).to contain_exactly(payee)
    end

    it "matches a name with surrounding whitespace" do
      expect(budget.payees.by_name("  #{payee.name}  ")).to contain_exactly(payee)
    end

    it "excludes a name that does not match" do
      expect(budget.payees.by_name("Different")).to be_empty
    end
  end

  describe "#merge_into" do
    subject(:merge_into) { payee.merge_into(other) }

    let(:budget) { create(:budget) }
    let(:other)  { create(:payee, budget: budget) }
    let(:payee)  { create(:payee, budget: budget) }

    it "reassigns the payee's transactions to the other payee" do
      transaction = create(:transaction, budget: budget, payee: payee)

      merge_into

      expect(transaction.reload.payee).to eq(other)
    end

    it "destroys the payee" do
      merge_into

      expect(described_class.exists?(payee.id)).to be(false)
    end

    it "returns the destroyed payee" do
      expect(merge_into).to eq(payee)
    end

    it "does not change a reconciled transaction's updated_at" do
      reconciled = create(:transaction, :reconciled, budget: budget, payee: payee, updated_at: 1.week.ago)

      expect { merge_into }.not_to(change { reconciled.reload.updated_at })
    end
  end

  describe "#suggested_subcategory_ids" do
    let(:budget) { create(:budget) }
    let(:payee)  { create(:payee, budget: budget) }

    it "returns an empty array when the payee has no categorized transactions" do
      create(:transaction, :transfer, budget: budget, payee: payee)

      expect(payee.suggested_subcategory_ids).to eq([])
    end

    it "returns the most-used subcategory IDs in order, ignoring uncategorized transactions" do
      common      = create(:category, :subcategory, budget: budget)
      less_common = create(:category, :subcategory, budget: budget)
      rare        = create(:category, :subcategory, budget: budget)

      3.times { create(:transaction, budget: budget, payee: payee, subcategory: common) }
      2.times { create(:transaction, budget: budget, payee: payee, subcategory: less_common) }
      create(:transaction, budget: budget, payee: payee, subcategory: rare)
      create(:transaction, :transfer, budget: budget, payee: payee)

      expect(payee.suggested_subcategory_ids).to eq([common.id, less_common.id, rare.id])
    end

    it "breaks ties on count by the most recent transaction date" do
      older = create(:category, :subcategory, budget: budget)
      newer = create(:category, :subcategory, budget: budget)

      create(:transaction, budget: budget, payee: payee, subcategory: older, date: 5.days.ago)
      create(:transaction, budget: budget, payee: payee, subcategory: newer, date: 1.day.ago)

      expect(payee.suggested_subcategory_ids).to eq([newer.id, older.id])
    end

    it "limits the number of subcategories" do
      (described_class::SUGGESTED_CATEGORY_LIMIT + 1).times do
        subcategory = create(:category, :subcategory, budget: budget)

        create(:transaction, budget: budget, payee: payee, subcategory: subcategory)
      end

      expect(payee.suggested_subcategory_ids.size).to eq(described_class::SUGGESTED_CATEGORY_LIMIT)
    end
  end

  describe "normalizations" do
    it "strips whitespace from the name" do
      payee = build(:payee, name: "  Grocery Store  ")

      expect(payee.name).to eq("Grocery Store")
    end
  end
end
