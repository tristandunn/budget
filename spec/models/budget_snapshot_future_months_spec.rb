# frozen_string_literal: true

require "rails_helper"

describe BudgetSnapshotFutureMonths do
  let(:available_amounts) { {} }
  let(:budget)            { create(:budget) }
  let(:date)              { Date.current.beginning_of_month }
  let(:subcategory)       { create(:category, :subcategory, budget: budget, with_snapshot: false) }

  describe "#to_a" do
    subject(:months) do
      described_class.new(
        budget,
        available_amounts:         available_amounts,
        date:                      date,
        monthly_target_categories: budget.subcategories.with_monthly_target,
        snapshot_range:            date.prev_year..date.next_year
      ).to_a
    end

    context "with more assigned future months than the limit" do
      before do
        (1..7).each do |offset|
          create(:category_snapshot, budget:          budget,
                                     category:        subcategory,
                                     date:            date.advance(months: offset),
                                     amount_assigned: 100)
        end
      end

      it "returns a snapshot per month up to the limit, ordered from the nearest" do
        expect(months.map(&:date)).to eq((1..6).map { |offset| date.advance(months: offset) })
      end
    end

    context "with assignments across several future months" do
      let(:available_amounts) { { subcategory.id => 100 } }

      before do
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   date:            date.next_month,
                                   amount_assigned: 50,
                                   amount_used:     20)
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   date:            date.advance(months: 2),
                                   amount_assigned: 10,
                                   amount_used:     0)
      end

      it "sums the available amounts through each month" do
        expect(months.map { |month| month.available_for(subcategory) }).to eq([130, 140])
      end
    end

    context "with an unassigned month between two assigned months" do
      let(:available_amounts) { { subcategory.id => 1_000 } }

      before do
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   date:            date.next_month,
                                   amount_assigned: 0,
                                   amount_used:     500)
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   date:            date.advance(months: 2),
                                   amount_assigned: 100,
                                   amount_used:     0)
      end

      it "excludes the unassigned month" do
        expect(months.map(&:date)).to eq([date.advance(months: 2)])
      end

      it "subtracts the unassigned month's usage from the later month" do
        expect(months.first.available_for(subcategory)).to eq(600)
      end
    end

    context "with a category that has no future snapshots" do
      let(:available_amounts) { { subcategory.id => 250 } }
      let(:other_subcategory) { create(:category, :subcategory, budget: budget, with_snapshot: false) }

      before do
        create(:category_snapshot, budget:          budget,
                                   category:        other_subcategory,
                                   date:            date.next_month,
                                   amount_assigned: 100)
      end

      it "carries the available amount through unchanged" do
        expect(months.first.available_for(subcategory)).to eq(250)
      end
    end

    context "with a category that first appears in a future month" do
      before do
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   date:            date.next_month,
                                   amount_assigned: 300,
                                   amount_used:     50)
      end

      it "adds the available amount for the category" do
        expect(months.first.available_for(subcategory)).to eq(250)
      end
    end

    context "with assignments in a top-level category" do
      let(:category) { create(:category, budget: budget, with_snapshot: false) }

      before do
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   date:            date.next_month,
                                   amount_assigned: 700,
                                   amount_used:     0)
        create(:category_snapshot, budget:          budget,
                                   category:        category,
                                   date:            date.advance(months: 2),
                                   amount_assigned: 900,
                                   amount_used:     0)
      end

      it "returns each month's own assigned total" do
        expect(months.map(&:total_assigned)).to eq([700, 900])
      end
    end

    context "with a snoozed future month" do
      let(:subcategory) do
        create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
      end

      before do
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   date:            date.next_month,
                                   amount_assigned: 100,
                                   amount_used:     0,
                                   metadata:        { "snoozed" => true })
      end

      it "returns the month's own snapshot" do
        expect(months.first.snoozed?(subcategory)).to be(true)
      end
    end

    context "with a monthly target funded in a future month" do
      let(:subcategory) do
        create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
      end

      before do
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   date:            date.next_month,
                                   amount_assigned: 200_00,
                                   amount_used:     0)
      end

      it "returns the funded percentage for the month" do
        expect(months.first.funded_percentage).to eq(100)
      end
    end

    context "without assigned future months" do
      before do
        create(:category_snapshot, budget:          budget,
                                   category:        subcategory,
                                   date:            date.next_month,
                                   amount_assigned: 0,
                                   amount_used:     500)
      end

      it "returns no months" do
        expect(months).to be_empty
      end
    end
  end
end
