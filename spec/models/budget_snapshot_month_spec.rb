# frozen_string_literal: true

require "rails_helper"

describe BudgetSnapshotMonth do
  let(:budget) { create(:budget) }

  describe "#current_month?" do
    context "when on the current month" do
      subject { described_class.new(budget) }

      it { is_expected.to be_current_month }
    end

    context "when not on the current month" do
      subject do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it { is_expected.not_to be_current_month }
    end
  end

  describe "#date" do
    context "without year and month parameters" do
      subject(:budget_snapshot_month) { described_class.new(budget) }

      it "defaults to the current month" do
        expect(budget_snapshot_month.date).to eq(Date.current.beginning_of_month)
      end
    end

    context "with valid year and month parameters" do
      subject(:budget_snapshot_month) do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it "returns the parsed date" do
        expect(budget_snapshot_month.date).to eq(next_month)
      end
    end

    context "with an invalid month parameter" do
      subject(:budget_snapshot_month) { described_class.new(budget, month: "invalid", year: "2026") }

      it "defaults to the current month" do
        expect(budget_snapshot_month.date).to eq(Date.current.beginning_of_month)
      end
    end

    context "with a date before the snapshot range" do
      subject(:budget_snapshot_month) { described_class.new(budget, month: "1", year: 5.years.ago.year.to_s) }

      it "clamps to the first month" do
        expect(budget_snapshot_month.date).to eq(budget_snapshot_month.snapshot_range.first)
      end
    end

    context "with a date after the snapshot range" do
      subject(:budget_snapshot_month) { described_class.new(budget, month: "1", year: 5.years.from_now.year.to_s) }

      it "clamps to the last month" do
        expect(budget_snapshot_month.date).to eq(budget_snapshot_month.snapshot_range.last)
      end
    end
  end

  describe "#first_month?" do
    context "when on the first month of the range" do
      subject(:budget_snapshot_month) { described_class.new(budget) }

      it { is_expected.to be_first_month }
    end

    context "when not on the first month of the range" do
      subject(:budget_snapshot_month) do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it { is_expected.not_to be_first_month }
    end
  end

  describe "#last_month?" do
    context "when on the last month of the range" do
      subject(:budget_snapshot_month) do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it { is_expected.to be_last_month }
    end

    context "when not on the last month of the range" do
      subject(:budget_snapshot_month) { described_class.new(budget) }

      it { is_expected.not_to be_last_month }
    end
  end

  describe "#next_date" do
    context "when on the last month" do
      subject(:budget_snapshot_month) do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it "returns the current date" do
        expect(budget_snapshot_month.next_date).to eq(budget_snapshot_month.date)
      end
    end

    context "when not on the last month" do
      subject(:budget_snapshot_month) { described_class.new(budget) }

      it "returns the next month" do
        expect(budget_snapshot_month.next_date).to eq(budget_snapshot_month.date.next_month)
      end
    end
  end

  describe "#previous_date" do
    context "when on the first month" do
      subject(:budget_snapshot_month) { described_class.new(budget) }

      it "returns the current date" do
        expect(budget_snapshot_month.previous_date).to eq(budget_snapshot_month.date)
      end
    end

    context "when not on the first month" do
      subject(:budget_snapshot_month) do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it "returns the previous month" do
        expect(budget_snapshot_month.previous_date).to eq(budget_snapshot_month.date.prev_month)
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

    context "with unassigned snapshots" do
      before do
        create(:category_snapshot, budget: budget, date: 3.months.ago.beginning_of_month, amount_assigned: 0)
      end

      it "excludes unassigned snapshots" do
        expect(snapshot_range).to eq(Date.current.beginning_of_month..1.month.from_now.beginning_of_month)
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
