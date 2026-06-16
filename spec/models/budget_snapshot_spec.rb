# frozen_string_literal: true

require "rails_helper"

describe BudgetSnapshot do
  let(:budget) { create(:budget) }

  describe "class" do
    subject { described_class.new(budget) }

    it { is_expected.to delegate_method(:current_month?).to(:snapshot_month) }
    it { is_expected.to delegate_method(:date).to(:snapshot_month) }
    it { is_expected.to delegate_method(:first_month?).to(:snapshot_month) }
    it { is_expected.to delegate_method(:last_month?).to(:snapshot_month) }
    it { is_expected.to delegate_method(:next_date).to(:snapshot_month) }
    it { is_expected.to delegate_method(:previous_date).to(:snapshot_month) }
    it { is_expected.to delegate_method(:snapshot_range).to(:snapshot_month) }
  end

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

  describe "#funded?" do
    subject(:budget_snapshot) { described_class.new(budget) }

    let(:subcategory) do
      create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
    end

    context "when the monthly targets are fully funded" do
      before do
        create(:category_snapshot, budget: budget, category: subcategory, amount_assigned: 200_00, amount_used: 0)
      end

      it { is_expected.to be_funded }
    end

    context "when the monthly targets are not fully funded" do
      before do
        create(:category_snapshot, budget: budget, category: subcategory, amount_assigned: 100_00, amount_used: 0)
      end

      it { is_expected.not_to be_funded }
    end
  end

  describe "#funded_percentage" do
    subject(:budget_snapshot) { described_class.new(budget) }

    context "without monthly targets" do
      it "returns zero" do
        expect(budget_snapshot.funded_percentage).to eq(0)
      end
    end

    context "with monthly targets" do
      let(:first_target)  do
        create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
      end
      let(:second_target) do
        create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
      end

      before do
        create(:category_snapshot, budget: budget, category: first_target, amount_assigned: 200_00, amount_used: 0)
        create(:category_snapshot, budget: budget, category: second_target, amount_assigned: 100_00, amount_used: 0)
      end

      it "returns the aggregate funded percentage across the targets" do
        expect(budget_snapshot.funded_percentage).to eq(75)
      end
    end

    context "when one target is overfunded and another is unfunded" do
      before do
        overfunded = create(:category, :subcategory, :with_monthly_spending_target, budget:        budget,
                                                                                    with_snapshot: false)
        unfunded   = create(:category, :subcategory, :with_monthly_spending_target, budget:        budget,
                                                                                    with_snapshot: false)

        create(:category_snapshot, budget: budget, category: overfunded, amount_assigned: 400_00, amount_used: 0)
        create(:category_snapshot, budget: budget, category: unfunded, amount_assigned: 0, amount_used: 0)
      end

      it "caps each target's contribution so overfunding does not mask the shortfall" do
        expect(budget_snapshot.funded_percentage).to eq(50)
      end
    end

    context "when a target is funded below zero" do
      before do
        overspent = create(:category, :subcategory, :with_monthly_savings_target, budget:        budget,
                                                                                  with_snapshot: false)

        create(:category_snapshot, budget: budget, category: overspent, amount_assigned: -100_00, amount_used: 0)
      end

      it "does not return a negative percentage" do
        expect(budget_snapshot.funded_percentage).to eq(0)
      end
    end
  end

  describe "#future_months" do
    subject(:budget_snapshot) { described_class.new(budget) }

    let(:category) { create(:category, budget: budget, with_snapshot: false) }

    context "with several assigned future months" do
      before do
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   date:            Date.current.beginning_of_month,
                                   amount_assigned: 100)

        (1..7).each do |offset|
          create(:category_snapshot, budget:          budget,
                                     category:        category,
                                     date:            offset.months.from_now.beginning_of_month,
                                     amount_assigned: 100)
        end
      end

      it "returns up to six future months ordered from the nearest" do
        expect(budget_snapshot.future_months.map(&:date)).to eq(
          (1..6).map { |offset| offset.months.from_now.beginning_of_month }
        )
      end
    end

    context "with a future month that has no assignments" do
      before do
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   date:            Date.current.beginning_of_month,
                                   amount_assigned: 100)
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   date:            1.month.from_now.beginning_of_month,
                                   amount_assigned: 0)
      end

      it "excludes the unassigned month" do
        expect(budget_snapshot.future_months).to be_empty
      end
    end

    context "with multiple categories assigned in the same future month" do
      let(:other_category) { create(:category, budget: budget, with_snapshot: false) }

      before do
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   date:            Date.current.beginning_of_month,
                                   amount_assigned: 100)

        [category, other_category].each do |assigned_category|
          create(:category_snapshot, budget:          budget,
                                     category:        assigned_category,
                                     date:            1.month.from_now.beginning_of_month,
                                     amount_assigned: 100)
        end
      end

      it "returns the month only once" do
        expect(budget_snapshot.future_months.size).to eq(1)
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

    context "with a snoozed monthly_savings target" do
      let(:subcategory) do
        create(:category, :subcategory, :with_monthly_savings_target, budget: budget, with_snapshot: false)
      end

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
        .with(category: subcategory, rollover: 0, snapshot: instance.snapshot_for(subcategory.id))
        .and_return(progress)
    end

    it { is_expected.to eq(progress) }

    context "with a balance rolled over from a prior month" do
      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 30_00,
               amount_used:     10_00,
               date:            1.month.ago.beginning_of_month)

        allow(TargetProgress).to receive(:new)
          .with(category: subcategory, rollover: 20_00, snapshot: instance.snapshot_for(subcategory.id))
          .and_return(progress)
      end

      it { is_expected.to eq(progress) }
    end
  end

  describe "#total_assigned" do
    subject(:budget_snapshot) { described_class.new(budget) }

    let(:category) { create(:category, budget: budget, with_snapshot: false) }

    before do
      create(:category_snapshot, budget: budget, category: category, amount_assigned: 300, amount_used: 0)
      create(:category_snapshot, budget:          budget,
                                 category:        create(:category, :inflow, budget: budget),
                                 amount_assigned: 999,
                                 amount_used:     0)
    end

    it "sums the assigned amount for the month, excluding inflow categories" do
      expect(budget_snapshot.total_assigned).to eq(300)
    end
  end

  describe "#total_available" do
    subject(:budget_snapshot) { described_class.new(budget) }

    let(:parent)      { create(:category, budget: budget, with_snapshot: false) }
    let(:subcategory) { create(:category, budget: budget, parent: parent, with_snapshot: false) }

    before do
      create(:category_snapshot, budget: budget, category: subcategory, amount_assigned: 300, amount_used: 90)
      create(:category_snapshot, budget:          budget,
                                 category:        create(:category, :inflow, budget: budget),
                                 amount_assigned: 999,
                                 amount_used:     0)
    end

    it "sums the cumulative available amount, excluding inflow categories" do
      expect(budget_snapshot.total_available).to eq(210)
    end
  end

  describe "#total_rollover" do
    subject(:budget_snapshot) { described_class.new(budget) }

    let(:parent)      { create(:category, budget: budget, with_snapshot: false) }
    let(:subcategory) { create(:category, budget: budget, parent: parent, with_snapshot: false) }

    before do
      create(:category_snapshot, budget:          budget,
                                 category:        subcategory,
                                 date:            1.month.ago.beginning_of_month,
                                 amount_assigned: 100,
                                 amount_used:     40)
      create(:category_snapshot, budget: budget, category: subcategory, amount_assigned: 300, amount_used: 150)
      create(:category_snapshot, budget: budget, category: parent, amount_assigned: 300, amount_used: 150)
    end

    it "returns the available amount carried in from prior months" do
      expect(budget_snapshot.total_rollover).to eq(60)
    end
  end

  describe "#total_used" do
    subject(:budget_snapshot) { described_class.new(budget) }

    let(:category) { create(:category, budget: budget, with_snapshot: false) }

    before do
      create(:category_snapshot, budget: budget, category: category, amount_assigned: 0, amount_used: 150)
      create(:category_snapshot, budget:          budget,
                                 category:        create(:category, :inflow, budget: budget),
                                 amount_assigned: 0,
                                 amount_used:     999)
    end

    it "sums the used amount for the month, excluding inflow categories" do
      expect(budget_snapshot.total_used).to eq(150)
    end
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

    context "with a positive rollover that completes an underfunded assignment" do
      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 1,
               amount_used:     0,
               date:            1.month.ago.beginning_of_month)
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: subcategory.target_amount - 1,
               amount_used:     0,
               date:            Date.current.beginning_of_month)
      end

      it { is_expected.to be(false) }
    end

    context "with a negative rollover that keeps a fully assigned target underfunded" do
      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 0,
               amount_used:     1,
               date:            1.month.ago.beginning_of_month)
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: subcategory.target_amount,
               amount_used:     0,
               date:            Date.current.beginning_of_month)
      end

      it { is_expected.to be(true) }
    end

    context "with a monthly_savings target and a large accumulated balance but nothing assigned this month" do
      let(:subcategory) do
        create(:category, :subcategory, :with_monthly_savings_target, budget: budget, with_snapshot: false)
      end

      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: subcategory.target_amount * 5,
               amount_used:     0,
               date:            1.month.ago.beginning_of_month)
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 0,
               amount_used:     0,
               date:            Date.current.beginning_of_month)
      end

      it { is_expected.to be(true) }
    end

    context "with a monthly_savings target after the month's set-aside is assigned" do
      let(:subcategory) do
        create(:category, :subcategory, :with_monthly_savings_target, budget: budget, with_snapshot: false)
      end

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
  end
end
