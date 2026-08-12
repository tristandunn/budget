# frozen_string_literal: true

require "rails_helper"

describe UpcomingTransactions do
  let(:budget)      { create(:budget) }
  let(:date)        { Date.current.beginning_of_month }
  let(:subcategory) { create(:category, :subcategory, budget: budget, with_snapshot: false) }

  let(:budget_snapshot) do
    instance_double(BudgetSnapshot, available_for: 50_000, date: date)
  end

  let(:upcoming_transactions) do
    described_class.new(budget_snapshot: budget_snapshot, category: subcategory)
  end

  describe "#any?" do
    subject { upcoming_transactions.any? }

    context "with upcoming transactions for the month" do
      before do
        create(:transaction, :upcoming, budget: budget, subcategory: subcategory, date: date)
      end

      it { is_expected.to be(true) }
    end

    context "without upcoming transactions for the month" do
      it { is_expected.to be(false) }
    end
  end

  describe "#available_after" do
    subject { upcoming_transactions.available_after }

    context "with upcoming transactions for the month" do
      before do
        create(:transaction, :upcoming, budget:      budget,
                                        subcategory: subcategory,
                                        amount:      -5_000,
                                        date:        date)
      end

      it { is_expected.to eq(45_000) }
    end

    context "with an upcoming refund for the month" do
      before do
        create(:transaction, :upcoming, budget:      budget,
                                        subcategory: subcategory,
                                        amount:      5_000,
                                        date:        date)
      end

      it { is_expected.to eq(55_000) }
    end

    context "with upcoming transactions for the month and an earlier one awaiting activation" do
      before do
        create(:transaction, :upcoming, budget:      budget,
                                        subcategory: subcategory,
                                        amount:      -5_000,
                                        date:        date.prev_month)
        create(:transaction, :upcoming, budget:      budget,
                                        subcategory: subcategory,
                                        amount:      -2_000,
                                        date:        date)
      end

      it { is_expected.to eq(43_000) }
    end

    context "without upcoming transactions for the month" do
      it { is_expected.to eq(50_000) }
    end
  end

  describe "#count" do
    subject { upcoming_transactions.count }

    context "with upcoming transactions for the month" do
      before do
        create(:transaction, :upcoming, budget: budget, subcategory: subcategory, date: date)
        create(:transaction, :upcoming, budget: budget, subcategory: subcategory, date: date.end_of_month)
      end

      it { is_expected.to eq(2) }
    end

    context "with an upcoming transaction in a later month" do
      before do
        create(:transaction, :upcoming, budget: budget, subcategory: subcategory, date: date.next_month)
      end

      it { is_expected.to eq(0) }
    end

    context "with an upcoming transaction in an earlier month" do
      before do
        create(:transaction, :upcoming, budget: budget, subcategory: subcategory, date: date.prev_month)
      end

      it { is_expected.to eq(1) }
    end

    context "with transactions in another status" do
      before do
        create(:transaction, budget: budget, subcategory: subcategory, date: date)
        create(:transaction, :cleared, budget: budget, subcategory: subcategory, date: date)
        create(:transaction, :reconciled, budget: budget, subcategory: subcategory, date: date)
      end

      it { is_expected.to eq(0) }
    end

    context "with an upcoming transaction for another category" do
      before do
        create(:transaction, :upcoming, budget: budget, date: date)
      end

      it { is_expected.to eq(0) }
    end

    context "without upcoming transactions for the month" do
      it { is_expected.to eq(0) }
    end
  end

  describe "#total" do
    subject { upcoming_transactions.total }

    context "with upcoming transactions for the month" do
      before do
        create(:transaction, :upcoming, budget:      budget,
                                        subcategory: subcategory,
                                        amount:      -3_000,
                                        date:        date)
        create(:transaction, :upcoming, budget:      budget,
                                        subcategory: subcategory,
                                        amount:      -2_000,
                                        date:        date.end_of_month)
      end

      it { is_expected.to eq(-5_000) }
    end

    context "with upcoming transactions for the month and an earlier one awaiting activation" do
      before do
        create(:transaction, :upcoming, budget:      budget,
                                        subcategory: subcategory,
                                        amount:      -4_000,
                                        date:        date.prev_month)
        create(:transaction, :upcoming, budget:      budget,
                                        subcategory: subcategory,
                                        amount:      -2_000,
                                        date:        date)
      end

      it { is_expected.to eq(-6_000) }
    end

    context "without upcoming transactions for the month" do
      it { is_expected.to eq(0) }
    end
  end
end
