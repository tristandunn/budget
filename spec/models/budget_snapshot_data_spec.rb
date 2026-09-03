# frozen_string_literal: true

require "rails_helper"

describe BudgetSnapshotData do
  subject(:data) { described_class.new(budget, date) }

  let(:budget)      { create(:budget) }
  let(:category)    { create(:category, budget: budget, with_snapshot: false) }
  let(:date)        { Date.current.beginning_of_month }

  describe "#available_amounts" do
    before do
      create(:category_snapshot, budget:          budget,
                                 category:        category,
                                 date:            date,
                                 amount_assigned: 200,
                                 amount_used:     150)
      create(:category_snapshot, budget:          budget,
                                 category:        category,
                                 date:            date.next_month,
                                 amount_assigned: 100,
                                 amount_used:     0)
    end

    it "sums the assigned minus used through the month" do
      expect(data.available_amounts).to eq(category.id => 50)
    end

    context "with preloaded amounts" do
      subject(:data) { described_class.new(budget, date, available_amounts: amounts) }

      let(:amounts) { { category.id => 1_000 } }

      it "returns the preloaded amounts" do
        expect(data.available_amounts).to be(amounts)
      end
    end
  end

  describe "#date" do
    it "returns the month it covers" do
      expect(data.date).to eq(date)
    end
  end

  describe "#future_months" do
    context "with several assigned future months" do
      before do
        (1..7).each do |offset|
          create(:category_snapshot, budget:          budget,
                                     category:        category,
                                     date:            date.advance(months: offset),
                                     amount_assigned: 100)
        end
      end

      it "returns the months capped at the limit, ordered from the nearest" do
        expect(data.future_months.map(&:date)).to eq(
          (1..described_class::FUTURE_MONTH_LIMIT).map { |offset| date.advance(months: offset) }
        )
      end

      it "loads the snapshots for each month" do
        expect(data.future_months.first.snapshots.keys).to eq([category.id])
      end

      it "shares the monthly target categories" do
        expect(data.future_months.first.monthly_target_categories).to be(data.monthly_target_categories)
      end

      it "memoizes the months" do
        months = data.future_months

        expect(data.future_months).to be(months)
      end
    end

    context "with a future month that has no assignments" do
      before do
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   date:            date.next_month,
                                   amount_assigned: 0)
      end

      it "excludes the unassigned month" do
        expect(data.future_months).to be_empty
      end
    end

    context "without any future months" do
      it "returns nothing" do
        expect(data.future_months).to be_empty
      end
    end

    context "with a future month that only has spending" do
      before do
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   date:            date,
                                   amount_assigned: 100,
                                   amount_used:     20)
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   date:            date.next_month,
                                   amount_assigned: 0,
                                   amount_used:     30)
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   date:            date.advance(months: 2),
                                   amount_assigned: 50,
                                   amount_used:     5)
      end

      it "carries the spending forward into the later month" do
        expect(data.future_months.first.available_amounts).to eq(category.id => 95)
      end

      it "matches the amounts loaded for the month on its own" do
        future_month = data.future_months.last

        expect(future_month.available_amounts).to eq(
          described_class.new(budget, future_month.date).available_amounts
        )
      end
    end
  end

  describe "#monthly_target_categories" do
    let!(:target_category) do
      create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
    end

    it "returns the subcategories with a monthly target" do
      expect(data.monthly_target_categories).to eq([target_category])
    end

    context "with preloaded categories" do
      subject(:data) { described_class.new(budget, date, monthly_target_categories: categories) }

      let(:categories) { [] }

      it "returns the preloaded categories" do
        expect(data.monthly_target_categories).to be(categories)
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

    it "indexes the month's snapshots by category id" do
      expect(data.snapshots).to eq(category.id => snapshot)
    end

    context "with preloaded snapshots" do
      subject(:data) { described_class.new(budget, date, snapshots: snapshots) }

      let(:snapshots) { {} }

      it "returns the preloaded snapshots" do
        expect(data.snapshots).to be(snapshots)
      end
    end
  end
end
