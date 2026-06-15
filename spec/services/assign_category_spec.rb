# frozen_string_literal: true

require "rails_helper"

describe AssignCategory do
  describe ".call" do
    let(:amount)               { Money.from_cents(5000) }
    let(:budget)               { subcategory.budget }
    let(:category_snapshot)    { subcategory.parent.snapshots.for_month(Date.current).first }
    let(:subcategory)          { create(:category, :subcategory) }
    let(:subcategory_snapshot) { subcategory.snapshots.for_month(Date.current).first }

    before do
      subcategory_snapshot.update!(amount_assigned: 0)
      category_snapshot.update!(amount_assigned: 0)
      budget.update!(available_to_assign: 100_000)

      described_class.call(budget: budget, subcategory: subcategory, amount: amount,
                           date: Date.current)
    end

    context "when assigning for the first time" do
      it "sets the subcategory snapshot amount assigned" do
        expect(subcategory_snapshot.reload.amount_assigned).to eq(5000)
      end

      it "sets the parent category snapshot amount assigned" do
        expect(category_snapshot.reload.amount_assigned).to eq(5000)
      end

      it "decrements the budget available to assign" do
        expect(budget.reload.available_to_assign).to eq(95_000)
      end
    end

    context "when increasing an existing assignment" do
      before do
        subcategory_snapshot.update!(amount_assigned: 3000)
        category_snapshot.update!(amount_assigned: 3000)
        budget.update!(available_to_assign: 100_000)

        described_class.call(budget: budget, subcategory: subcategory, amount: amount,
                             date: Date.current)
      end

      it "updates the subcategory snapshot amount assigned" do
        expect(subcategory_snapshot.reload.amount_assigned).to eq(5000)
      end

      it "updates the parent category snapshot by the delta" do
        expect(category_snapshot.reload.amount_assigned).to eq(5000)
      end

      it "decrements the budget available to assign by the delta" do
        expect(budget.reload.available_to_assign).to eq(98_000)
      end
    end

    context "when reducing an existing assignment" do
      let(:amount) { Money.from_cents(2000) }

      before do
        subcategory_snapshot.update!(amount_assigned: 5000)
        category_snapshot.update!(amount_assigned: 5000)
        budget.update!(available_to_assign: 100_000)

        described_class.call(budget: budget, subcategory: subcategory, amount: amount,
                             date: Date.current)
      end

      it "updates the subcategory snapshot amount assigned" do
        expect(subcategory_snapshot.reload.amount_assigned).to eq(2000)
      end

      it "updates the parent category snapshot by the delta" do
        expect(category_snapshot.reload.amount_assigned).to eq(2000)
      end

      it "increments the budget available to assign by the returned amount" do
        expect(budget.reload.available_to_assign).to eq(103_000)
      end
    end

    context "with a refund inflow into the category" do
      before do
        subcategory_snapshot.update!(amount_assigned: 5000, amount_used: 0)
        category_snapshot.update!(amount_assigned: 5000, amount_used: 0)
        budget.update!(available_to_assign: 100_000)

        CreateTransaction.call(
          transaction: build(:transaction, account:     create(:account, budget: budget),
                                           budget:      budget,
                                           subcategory: subcategory,
                                           amount:      2000)
        )

        described_class.call(budget: budget, subcategory: subcategory, amount: amount,
                             date: Date.current)
      end

      it "leaves the subcategory snapshot amount assigned unchanged" do
        expect(subcategory_snapshot.reload.amount_assigned).to eq(5000)
      end

      it "preserves the refund in the available balance" do
        expect(subcategory_snapshot.reload.amount_remaining).to eq(7000)
      end

      it "does not drain the refund into available to assign" do
        expect(budget.reload.available_to_assign).to eq(100_000)
      end
    end
  end
end
