# frozen_string_literal: true

require "rails_helper"

describe BudgetSnapshotMonth do
  subject(:snapshot_month) { described_class.new(budget, date) }

  let(:budget)   { create(:budget) }
  let(:category) { create(:category, budget: budget, with_snapshot: false) }
  let(:date)     { Date.current.beginning_of_month }

  describe "#available_amounts" do
    before do
      create(:category_snapshot, budget:          budget,
                                 category:        category,
                                 amount_assigned: 300,
                                 amount_used:     320,
                                 date:            date.prev_month)
      create(:category_snapshot, budget:          budget,
                                 category:        category,
                                 amount_assigned: 200,
                                 amount_used:     150,
                                 date:            date)
      create(:category_snapshot, budget:          budget,
                                 category:        category,
                                 amount_assigned: 100,
                                 amount_used:     0,
                                 date:            date.next_month)
    end

    it "sums the assigned minus used through the month" do
      expect(snapshot_month.available_amounts).to eq(category.id => 30)
    end

    context "with preloaded amounts" do
      subject(:snapshot_month) { described_class.new(budget, date, available_amounts: amounts) }

      let(:amounts) { { category.id => 1_000 } }

      it "returns the preloaded amounts" do
        expect(snapshot_month.available_amounts).to be(amounts)
      end
    end
  end

  describe "#date" do
    it "returns the month it covers" do
      expect(snapshot_month.date).to eq(date)
    end
  end

  describe "#future_months" do
    context "with several assigned future months" do
      before do
        (1..7).each do |offset|
          create(:category_snapshot, budget:          budget,
                                     category:        category,
                                     amount_assigned: 100,
                                     date:            date.advance(months: offset))
        end
      end

      it "returns the months capped at the limit, ordered from the nearest" do
        expect(snapshot_month.future_months.map(&:date)).to eq(
          (1..described_class::FUTURE_MONTH_LIMIT).map { |offset| date.advance(months: offset) }
        )
      end

      it "loads the snapshots for each month" do
        expect(snapshot_month.future_months.first.snapshots.keys).to eq([category.id])
      end

      it "shares the monthly target categories" do
        categories = snapshot_month.future_months.first.monthly_target_categories

        expect(categories).to be(snapshot_month.monthly_target_categories)
      end

      it "memoizes the months" do
        months = snapshot_month.future_months

        expect(snapshot_month.future_months).to be(months)
      end
    end

    context "with several categories assigned in the same future month" do
      let(:other_category) { create(:category, budget: budget, with_snapshot: false) }

      before do
        [category, other_category].each do |assigned_category|
          create(:category_snapshot, budget:          budget,
                                     category:        assigned_category,
                                     amount_assigned: 100,
                                     date:            date.next_month)
        end
      end

      it "returns the month only once" do
        expect(snapshot_month.future_months.map(&:date)).to eq([date.next_month])
      end
    end

    context "with a future month that has no assignments" do
      before do
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   amount_assigned: 0,
                                   date:            date.next_month)
      end

      it "excludes the unassigned month" do
        expect(snapshot_month.future_months).to be_empty
      end
    end

    context "without any future months" do
      it "returns nothing" do
        expect(snapshot_month.future_months).to be_empty
      end
    end

    context "with a future month that only has spending" do
      before do
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   amount_assigned: 100,
                                   amount_used:     20,
                                   date:            date)
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   amount_assigned: 0,
                                   amount_used:     30,
                                   date:            date.next_month)
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   amount_assigned: 50,
                                   amount_used:     5,
                                   date:            date.advance(months: 2))
      end

      it "carries the spending forward into the later month" do
        expect(snapshot_month.future_months.first.available_amounts).to eq(category.id => 95)
      end

      it "matches the amounts loaded for the month on its own" do
        future_month = snapshot_month.future_months.last

        expect(future_month.available_amounts).to eq(
          described_class.new(budget, future_month.date).available_amounts
        )
      end
    end

    context "with a category that skips a future month" do
      let(:other_subcategory) { create(:category, budget: budget, parent: category, with_snapshot: false) }
      let(:subcategory)       { create(:category, budget: budget, parent: category, with_snapshot: false) }

      before do
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   amount_assigned: 250,
                                   amount_used:     0,
                                   date:            date)
        create(:category_snapshot, budget:          budget,
                                   category:        other_subcategory,
                                   amount_assigned: 100,
                                   date:            date.next_month)
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   amount_assigned: 50,
                                   amount_used:     0,
                                   date:            date.advance(months: 2))
      end

      it "carries the amount through the skipped month" do
        amounts = snapshot_month.future_months.map do |future_month|
          future_month.available_amounts[subcategory.id]
        end

        expect(amounts).to eq([250, 300])
      end
    end

    context "with a category that first appears in a future month" do
      let(:other_subcategory) { create(:category, budget: budget, parent: category, with_snapshot: false) }
      let(:subcategory)       { create(:category, budget: budget, parent: category, with_snapshot: false) }

      before do
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   amount_assigned: 100,
                                   amount_used:     0,
                                   date:            date)
        create(:category_snapshot, budget:          budget,
                                   category:        other_subcategory,
                                   amount_assigned: 300,
                                   amount_used:     50,
                                   date:            date.next_month)
      end

      it "adds the category to the amounts" do
        expect(snapshot_month.future_months.first.available_amounts).to eq(subcategory.id       => 100,
                                                                           other_subcategory.id => 250)
      end
    end
  end

  describe "#monthly_target_categories" do
    let!(:target_category) do
      create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
    end

    it "returns the subcategories with a monthly target" do
      expect(snapshot_month.monthly_target_categories).to eq([target_category])
    end

    context "with preloaded categories" do
      subject(:snapshot_month) { described_class.new(budget, date, monthly_target_categories: categories) }

      let(:categories) { [] }

      it "returns the preloaded categories" do
        expect(snapshot_month.monthly_target_categories).to be(categories)
      end
    end
  end

  describe "#snapshots" do
    let!(:snapshot) do
      create(:category_snapshot, budget: budget, category: category, date: date)
    end

    before do
      create(:category_snapshot, budget: budget, category: category, date: date.next_month)
    end

    it "indexes the month's snapshots by category ID" do
      expect(snapshot_month.snapshots).to eq(category.id => snapshot)
    end

    context "with preloaded snapshots" do
      subject(:snapshot_month) { described_class.new(budget, date, snapshots: snapshots) }

      let(:snapshots) { {} }

      it "returns the preloaded snapshots" do
        expect(snapshot_month.snapshots).to be(snapshots)
      end
    end
  end
end
