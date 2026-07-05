# frozen_string_literal: true

require "rails_helper"

describe CategorySummary do
  subject(:summary) do
    described_class.new(
      budget,
      budget_snapshot:          budget_snapshot,
      ids:                      [first.id, second.id],
      previous_budget_snapshot: previous_budget_snapshot
    )
  end

  let(:budget)          { create(:budget) }
  let(:budget_snapshot) { BudgetSnapshot.new(budget) }
  let(:first)           { create(:category, :subcategory, budget: budget, name: "Rent", with_snapshot: false) }
  let(:second)          { create(:category, :subcategory, budget: budget, name: "Groceries", with_snapshot: false) }

  let(:previous_budget_snapshot) do
    BudgetSnapshot.new(budget, month: 1.month.ago.month, year: 1.month.ago.year)
  end

  before do
    create(:category_snapshot, budget:          budget,
                               category:        first,
                               amount_assigned: 20_000,
                               amount_used:     5_000,
                               date:            1.month.ago.beginning_of_month)
    create(:category_snapshot, budget:          budget,
                               category:        second,
                               amount_assigned: 10_000,
                               amount_used:     2_000,
                               date:            1.month.ago.beginning_of_month)
    create(:category_snapshot, budget:          budget,
                               category:        first,
                               amount_assigned: 40_000,
                               amount_used:     10_000)
    create(:category_snapshot, budget:          budget,
                               category:        second,
                               amount_assigned: 25_000,
                               amount_used:     5_000)
  end

  describe "class" do
    it { is_expected.to delegate_method(:size).to(:categories) }
  end

  describe "#activity" do
    it "sums the negated activity across the selection" do
      expect(summary.activity).to eq(-15_000)
    end
  end

  describe "#assigned" do
    it "sums the amount assigned across the selection" do
      expect(summary.assigned).to eq(65_000)
    end
  end

  describe "#available" do
    it "sums the amount available across the selection" do
      expect(summary.available).to eq(73_000)
    end
  end

  describe "#categories" do
    it "resolves the selected subcategories" do
      expect(summary.categories).to contain_exactly(first, second)
    end

    it "ignores ids outside the budget" do
      other   = create(:category, :subcategory)
      summary = described_class.new(
        budget,
        budget_snapshot:          budget_snapshot,
        ids:                      [first.id, other.id],
        previous_budget_snapshot: previous_budget_snapshot
      )

      expect(summary.categories).to contain_exactly(first)
    end
  end

  describe "#names" do
    it "returns the sorted subcategory names" do
      expect(summary.names).to eq(%w(Groceries Rent))
    end
  end

  describe "#rollover" do
    it "sums the previous month's available across the selection" do
      expect(summary.rollover).to eq(23_000)
    end

    context "without a previous budget snapshot" do
      let(:previous_budget_snapshot) { nil }

      it "treats the rollover as zero" do
        expect(summary.rollover).to eq(0)
      end
    end
  end
end
