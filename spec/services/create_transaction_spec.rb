# frozen_string_literal: true

require "rails_helper"

describe CreateTransaction do
  describe ".call" do
    context "when the category has a parent" do
      let(:parent)            { create(:category) }
      let(:category)          { create(:category, :subcategory, parent: parent) }
      let(:category_snapshot) { category.snapshots.for_month(Date.current).first }
      let(:parent_snapshot)   { parent.snapshots.for_month(Date.current).first }
      let(:transaction)       { build(:transaction, category: category, budget: category.budget, amount: 1000) }

      it "increments the category snapshot amount_used" do
        expect { described_class.call(transaction: transaction) }
          .to change { category_snapshot.reload.amount_used }.by(1000)
      end

      it "increments the parent category snapshot amount_used" do
        expect { described_class.call(transaction: transaction) }
          .to change { parent_snapshot.reload.amount_used }.by(1000)
      end

      it "saves the transaction" do
        expect { described_class.call(transaction: transaction) }
          .to change(transaction, :persisted?).from(false).to(true)
      end
    end

    context "when the category does not have a parent" do
      let(:category)          { create(:category) }
      let(:category_snapshot) { category.snapshots.for_month(Date.current).first }
      let(:transaction)       { build(:transaction, category: category, budget: category.budget, amount: 500) }

      it "increments the category snapshot amount_used" do
        expect { described_class.call(transaction: transaction) }
          .to change { category_snapshot.reload.amount_used }.by(500)
      end

      it "saves the transaction" do
        expect { described_class.call(transaction: transaction) }
          .to change(transaction, :persisted?).from(false).to(true)
      end
    end
  end
end
