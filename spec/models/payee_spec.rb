# frozen_string_literal: true

require "rails_helper"

describe Payee do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to belong_to(:budget) }
    it { is_expected.to have_many(:transactions).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject(:payee) { create(:payee) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:budget_id) }
  end

  describe "#previous_subcategory_id" do
    let(:budget) { create(:budget) }
    let(:payee)  { create(:payee, budget: budget) }

    it "returns nil when the payee has no transactions" do
      expect(payee.previous_subcategory_id).to be_nil
    end

    it "returns nil when the payee's only transactions have no subcategory" do
      create(:transaction, budget: budget, payee: payee, subcategory: nil)

      expect(payee.previous_subcategory_id).to be_nil
    end

    it "returns the most recent categorized subcategory id" do
      older = create(:category, :subcategory, budget: budget)
      newer = create(:category, :subcategory, budget: budget)

      create(:transaction, budget: budget, payee: payee, subcategory: older, date: 5.days.ago)
      create(:transaction, budget: budget, payee: payee, subcategory: newer, date: 1.day.ago)

      expect(payee.previous_subcategory_id).to eq(newer.id)
    end

    it "breaks ties on the same date by the most recent transaction id" do
      older = create(:category, :subcategory, budget: budget)
      newer = create(:category, :subcategory, budget: budget)

      create(:transaction, budget: budget, payee: payee, subcategory: older, date: Date.current)
      create(:transaction, budget: budget, payee: payee, subcategory: newer, date: Date.current)

      expect(payee.previous_subcategory_id).to eq(newer.id)
    end

    it "skips uncategorized transactions when finding the most recent" do
      categorized = create(:category, :subcategory, budget: budget)

      create(:transaction, budget: budget, payee: payee, subcategory: categorized, date: 5.days.ago)
      create(:transaction, budget: budget, payee: payee, subcategory: nil, date: 1.day.ago)

      expect(payee.previous_subcategory_id).to eq(categorized.id)
    end
  end

  describe "normalizations" do
    it "strips whitespace from the name" do
      payee = build(:payee, name: "  Grocery Store  ")

      expect(payee.name).to eq("Grocery Store")
    end
  end
end
