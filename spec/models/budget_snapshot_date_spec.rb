# frozen_string_literal: true

require "rails_helper"

describe BudgetSnapshotDate do
  let(:budget) { create(:budget) }

  describe ".parse" do
    it "returns the first day of the month" do
      expect(described_class.parse("2026", "3")).to eq(Date.new(2026, 3))
    end

    it "returns nil without a year" do
      expect(described_class.parse(nil, "3")).to be_nil
    end

    it "returns nil for a year that is not a scalar" do
      expect(described_class.parse(["2026"], "3")).to be_nil
    end

    it "returns nil for a month out of range" do
      expect(described_class.parse("2026", "13")).to be_nil
    end

    it "returns nil for a month that is not a number" do
      expect(described_class.parse("2026", "invalid")).to be_nil
    end
  end

  describe "#current_month?" do
    context "when on the current month" do
      subject { described_class.new(budget) }

      it { is_expected.to be_current_month }
    end

    context "when not on the current month" do
      subject do
        described_class.new(budget, date: next_month)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it { is_expected.not_to be_current_month }
    end
  end

  describe "#date" do
    context "without a date" do
      subject(:budget_snapshot_date) { described_class.new(budget) }

      it "defaults to the current month" do
        expect(budget_snapshot_date.date).to eq(Date.current.beginning_of_month)
      end

      it "does not build the snapshot range" do
        allow(budget).to receive(:category_snapshots).and_call_original

        budget_snapshot_date.date

        expect(budget).not_to have_received(:category_snapshots)
      end
    end

    context "with a date in the range" do
      subject(:budget_snapshot_date) do
        described_class.new(budget, date: next_month)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it "returns the requested date" do
        expect(budget_snapshot_date.date).to eq(next_month)
      end
    end

    context "with a date before the snapshot range" do
      subject(:budget_snapshot_date) { described_class.new(budget, date: Date.new(5.years.ago.year, 1)) }

      it "clamps to the first month" do
        expect(budget_snapshot_date.date).to eq(budget_snapshot_date.snapshot_range.first)
      end
    end

    context "with a date after the snapshot range" do
      subject(:budget_snapshot_date) { described_class.new(budget, date: Date.new(5.years.from_now.year, 1)) }

      it "clamps to the last month" do
        expect(budget_snapshot_date.date).to eq(budget_snapshot_date.snapshot_range.last)
      end
    end
  end

  describe "#first_month?" do
    context "when on the first month of the range" do
      subject(:budget_snapshot_date) { described_class.new(budget) }

      it { is_expected.to be_first_month }
    end

    context "when not on the first month of the range" do
      subject(:budget_snapshot_date) do
        described_class.new(budget, date: next_month)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it { is_expected.not_to be_first_month }
    end
  end

  describe "#future_month?" do
    context "when on a month after the current month" do
      subject(:budget_snapshot_date) do
        described_class.new(budget, date: next_month)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it { is_expected.to be_future_month }
    end

    context "when on the current month" do
      subject(:budget_snapshot_date) { described_class.new(budget) }

      it { is_expected.not_to be_future_month }
    end

    context "when on a month before the current month" do
      subject(:budget_snapshot_date) do
        described_class.new(budget, date: previous_month)
      end

      let(:previous_month) { 1.month.ago.beginning_of_month }

      before do
        create(:category_snapshot, budget: budget, date: previous_month)
      end

      it { is_expected.not_to be_future_month }
    end
  end

  describe "#last_month?" do
    context "when on the last month of the range" do
      subject(:budget_snapshot_date) do
        described_class.new(budget, date: next_month)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it { is_expected.to be_last_month }
    end

    context "when not on the last month of the range" do
      subject(:budget_snapshot_date) { described_class.new(budget) }

      it { is_expected.not_to be_last_month }
    end
  end

  describe "#next_date" do
    context "when on the last month" do
      subject(:budget_snapshot_date) do
        described_class.new(budget, date: next_month)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it "returns the current date" do
        expect(budget_snapshot_date.next_date).to eq(budget_snapshot_date.date)
      end
    end

    context "when not on the last month" do
      subject(:budget_snapshot_date) { described_class.new(budget) }

      it "returns the next month" do
        expect(budget_snapshot_date.next_date).to eq(budget_snapshot_date.date.next_month)
      end
    end
  end

  describe "#previous_date" do
    context "when on the first month" do
      subject(:budget_snapshot_date) { described_class.new(budget) }

      it "returns the current date" do
        expect(budget_snapshot_date.previous_date).to eq(budget_snapshot_date.date)
      end
    end

    context "when not on the first month" do
      subject(:budget_snapshot_date) do
        described_class.new(budget, date: next_month)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it "returns the previous month" do
        expect(budget_snapshot_date.previous_date).to eq(budget_snapshot_date.date.prev_month)
      end
    end
  end

  describe "#snapshot_range" do
    subject(:snapshot_range) { described_class.new(budget).snapshot_range }

    context "without snapshots" do
      it "returns the current month to the next month" do
        expect(snapshot_range).to eq(Date.current.beginning_of_month..1.month.from_now.beginning_of_month)
      end
    end

    context "with past snapshots" do
      before do
        create(:category_snapshot, budget: budget, date: 3.months.ago.beginning_of_month)
      end

      it "returns the earliest snapshot month to the next month" do
        expect(snapshot_range).to eq(3.months.ago.beginning_of_month..1.month.from_now.beginning_of_month)
      end
    end

    context "with future snapshots" do
      before do
        create(:category_snapshot, budget: budget, date: Date.current.beginning_of_month)
        create(:category_snapshot, budget: budget, date: 2.months.from_now.beginning_of_month)
      end

      it "returns the current month to one month past the latest future snapshot" do
        expect(snapshot_range).to eq(Date.current.beginning_of_month..3.months.from_now.beginning_of_month)
      end
    end

    context "with past and future snapshots" do
      before do
        create(:category_snapshot, budget: budget, date: 3.months.ago.beginning_of_month)
        create(:category_snapshot, budget: budget, date: 2.months.from_now.beginning_of_month)
      end

      it "returns the full range" do
        expect(snapshot_range).to eq(3.months.ago.beginning_of_month..3.months.from_now.beginning_of_month)
      end
    end

    context "with zeroed out past snapshots" do
      before do
        create(
          :category_snapshot,
          amount_assigned: 0,
          amount_used:     0,
          budget:          budget,
          date:            3.months.ago.beginning_of_month
        )
      end

      it "includes the month of the zeroed out snapshot" do
        expect(snapshot_range).to eq(3.months.ago.beginning_of_month..1.month.from_now.beginning_of_month)
      end
    end

    context "with zeroed out future snapshots" do
      before do
        create(
          :category_snapshot,
          amount_assigned: 0,
          amount_used:     0,
          budget:          budget,
          date:            2.months.from_now.beginning_of_month
        )
      end

      it "excludes the month of the zeroed out snapshot" do
        expect(snapshot_range).to eq(Date.current.beginning_of_month..1.month.from_now.beginning_of_month)
      end
    end

    context "with a future snapshot that only has spending" do
      before do
        create(
          :category_snapshot,
          amount_assigned: 0,
          amount_used:     100,
          budget:          budget,
          date:            2.months.from_now.beginning_of_month
        )
      end

      it "returns the current month to one month past the latest spending" do
        expect(snapshot_range).to eq(Date.current.beginning_of_month..3.months.from_now.beginning_of_month)
      end
    end

    context "with a provided range" do
      before do
        create(:category_snapshot, budget: budget, date: 3.months.ago.beginning_of_month)
      end

      it "returns the provided range without computing one" do
        range = Date.current.beginning_of_month..1.month.from_now.beginning_of_month

        expect(described_class.new(budget, snapshot_range: range).snapshot_range).to eq(range)
      end
    end
  end
end
