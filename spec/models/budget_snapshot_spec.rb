# frozen_string_literal: true

require "rails_helper"

describe BudgetSnapshot do
  let(:budget) { create(:budget) }

  describe "#available_for" do
    subject(:budget_snapshot) { described_class.new(budget) }

    let(:subcategory) { create(:category, :subcategory, budget: budget, with_snapshot: false) }

    context "with a single snapshot" do
      before do
        create(:category_snapshot, budget: budget, category: subcategory, amount_assigned: 200, amount_used: 150)
      end

      it "returns the difference between assigned and used" do
        expect(budget_snapshot.available_for(subcategory)).to eq(50)
      end
    end

    context "with snapshots across multiple months" do
      before do
        create(:category_snapshot, budget: budget, category: subcategory, amount_assigned: 100, amount_used: 70)
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   date:            1.month.ago.beginning_of_month,
                                   amount_assigned: 200,
                                   amount_used:     250)
      end

      it "sums all snapshots through the displayed month" do
        expect(budget_snapshot.available_for(subcategory)).to eq(-20)
      end
    end

    context "with a snapshot in a future month" do
      before do
        create(:category_snapshot, budget: budget, category: subcategory, amount_assigned: 100, amount_used: 20)
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   date:            2.months.from_now.beginning_of_month,
                                   amount_assigned: 500)
      end

      it "excludes snapshots after the displayed month" do
        expect(budget_snapshot.available_for(subcategory)).to eq(80)
      end
    end

    context "with a group category" do
      let(:first_subcategory)  { create(:category, budget: budget, parent: parent, with_snapshot: false) }
      let(:parent)             { create(:category, budget: budget, with_snapshot: false) }
      let(:second_subcategory) { create(:category, budget: budget, parent: parent, with_snapshot: false) }

      before do
        create(:category_snapshot, budget: budget, category: first_subcategory, amount_assigned: 100, amount_used: 40)
        create(:category_snapshot, budget: budget, category: second_subcategory, amount_assigned: 300, amount_used: 150)
        create(:category_snapshot, budget: budget, category: parent, amount_assigned: 999, amount_used: 999)
      end

      it "sums the available amounts of its subcategories and ignores its own snapshot" do
        expect(budget_snapshot.available_for(parent)).to eq(210)
      end
    end

    context "without snapshots" do
      it "returns zero" do
        expect(budget_snapshot.available_for(subcategory)).to eq(0)
      end
    end
  end

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
      subject(:budget_snapshot) { described_class.new(budget) }

      it "defaults to the current month" do
        expect(budget_snapshot.date).to eq(Date.current.beginning_of_month)
      end
    end

    context "with valid year and month parameters" do
      subject(:budget_snapshot) do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it "returns the parsed date" do
        expect(budget_snapshot.date).to eq(next_month)
      end
    end

    context "with an invalid month parameter" do
      subject(:budget_snapshot) { described_class.new(budget, month: "invalid", year: "2026") }

      it "defaults to the current month" do
        expect(budget_snapshot.date).to eq(Date.current.beginning_of_month)
      end
    end

    context "with a date before the snapshot range" do
      subject(:budget_snapshot) { described_class.new(budget, month: "1", year: 5.years.ago.year.to_s) }

      it "clamps to the first month" do
        expect(budget_snapshot.date).to eq(budget_snapshot.snapshot_range.first)
      end
    end

    context "with a date after the snapshot range" do
      subject(:budget_snapshot) { described_class.new(budget, month: "1", year: 5.years.from_now.year.to_s) }

      it "clamps to the last month" do
        expect(budget_snapshot.date).to eq(budget_snapshot.snapshot_range.last)
      end
    end
  end

  describe "#first_month?" do
    context "when on the first month of the range" do
      subject(:budget_snapshot) { described_class.new(budget) }

      it { is_expected.to be_first_month }
    end

    context "when not on the first month of the range" do
      subject(:budget_snapshot) do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it { is_expected.not_to be_first_month }
    end
  end

  describe "#last_month?" do
    context "when on the last month of the range" do
      subject(:budget_snapshot) do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it { is_expected.to be_last_month }
    end

    context "when not on the last month of the range" do
      subject(:budget_snapshot) { described_class.new(budget) }

      it { is_expected.not_to be_last_month }
    end
  end

  describe "#next_date" do
    context "when on the last month" do
      subject(:budget_snapshot) do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it "returns the current date" do
        expect(budget_snapshot.next_date).to eq(budget_snapshot.date)
      end
    end

    context "when not on the last month" do
      subject(:budget_snapshot) { described_class.new(budget) }

      it "returns the next month" do
        expect(budget_snapshot.next_date).to eq(budget_snapshot.date.next_month)
      end
    end
  end

  describe "#previous_date" do
    context "when on the first month" do
      subject(:budget_snapshot) { described_class.new(budget) }

      it "returns the current date" do
        expect(budget_snapshot.previous_date).to eq(budget_snapshot.date)
      end
    end

    context "when not on the first month" do
      subject(:budget_snapshot) do
        described_class.new(budget, month: next_month.month.to_s, year: next_month.year.to_s)
      end

      let(:next_month) { 1.month.from_now.beginning_of_month }

      it "returns the previous month" do
        expect(budget_snapshot.previous_date).to eq(budget_snapshot.date.prev_month)
      end
    end
  end

  describe "#snapshot_for" do
    subject(:budget_snapshot) { described_class.new(budget) }

    let(:subcategory)          { create(:category, :subcategory, budget: budget) }
    let(:subcategory_snapshot) { subcategory.snapshots.for_month(Date.current).first }

    it "returns the snapshot for a known category" do
      subcategory_snapshot

      expect(budget_snapshot.snapshot_for(subcategory.id)).to eq(subcategory_snapshot)
    end

    it "returns a new CategorySnapshot for an unknown category" do
      expect(budget_snapshot.snapshot_for(:nonexistent)).to be_a_new(CategorySnapshot)
    end

    it "returns the same instance for repeated lookups of an unknown category" do
      first_lookup  = budget_snapshot.snapshot_for(:nonexistent)
      second_lookup = budget_snapshot.snapshot_for(:nonexistent)

      expect(first_lookup).to be(second_lookup)
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
  end

  describe "#snoozed?" do
    subject { instance.snoozed?(subcategory) }

    let(:instance)    { described_class.new(budget) }
    let(:subcategory) do
      create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
    end

    context "without a snapshot for the displayed month" do
      it { is_expected.to be(false) }
    end

    context "with a snapshot that is not snoozed" do
      before do
        create(:category_snapshot,
               budget:   budget,
               category: subcategory,
               date:     Date.current.beginning_of_month,
               metadata: {})
      end

      it { is_expected.to be(false) }
    end

    context "with a snapshot that is snoozed" do
      before do
        create(:category_snapshot,
               budget:   budget,
               category: subcategory,
               date:     Date.current.beginning_of_month,
               metadata: { "snoozed" => true })
      end

      it { is_expected.to be(true) }
    end

    context "with a snoozed snapshot but the target has since been removed" do
      let(:subcategory) { create(:category, :subcategory, budget: budget, with_snapshot: false) }

      before do
        create(:category_snapshot,
               budget:   budget,
               category: subcategory,
               date:     Date.current.beginning_of_month,
               metadata: { "snoozed" => true })
      end

      it { is_expected.to be(false) }
    end

    context "with a top-level category" do
      let(:subcategory) { create(:category, budget: budget, with_snapshot: false) }

      it { is_expected.to be(false) }
    end
  end

  describe "#target_progress_for" do
    subject { instance.target_progress_for(subcategory) }

    let(:instance)    { described_class.new(budget) }
    let(:progress)    { instance_double(TargetProgress) }
    let(:subcategory) { create(:category, :subcategory, budget: budget) }

    before do
      allow(TargetProgress).to receive(:new)
        .with(category: subcategory, snapshot: instance.snapshot_for(subcategory.id))
        .and_return(progress)
    end

    it { is_expected.to eq(progress) }
  end

  describe "#underfunded?" do
    subject(:underfunded?) { instance.underfunded?(subcategory) }

    let(:instance)    { described_class.new(budget) }
    let(:subcategory) do
      create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
    end

    context "without a target" do
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      it { is_expected.to be(false) }
    end

    context "with a monthly_spending target where assigned is below the target and available is positive" do
      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: subcategory.target_amount - 1,
               amount_used:     0,
               date:            Date.current.beginning_of_month)
      end

      it { is_expected.to be(true) }
    end

    context "with a monthly_spending target where assigned is below the target and available is zero" do
      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: subcategory.target_amount - 1,
               amount_used:     subcategory.target_amount - 1,
               date:            Date.current.beginning_of_month)
      end

      it { is_expected.to be(true) }
    end

    context "with a monthly_spending target where assigned matches the target" do
      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: subcategory.target_amount,
               amount_used:     0,
               date:            Date.current.beginning_of_month)
      end

      it { is_expected.to be(false) }
    end

    context "with a monthly_spending target where assigned is below the target but available is overspent" do
      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: subcategory.target_amount - 1,
               amount_used:     subcategory.target_amount,
               date:            Date.current.beginning_of_month)
      end

      it { is_expected.to be(false) }
    end

    context "with a monthly_spending target that is snoozed for the displayed month" do
      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: subcategory.target_amount - 1,
               amount_used:     0,
               metadata:        { "snoozed" => true },
               date:            Date.current.beginning_of_month)
      end

      it { is_expected.to be(false) }
    end
  end
end
