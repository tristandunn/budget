# frozen_string_literal: true

require "rails_helper"

describe CreateTransaction do
  describe ".call" do
    let(:category)          { create(:category, :subcategory, parent: parent) }
    let(:category_snapshot) { category.snapshots.for_month(Date.current).first }
    let(:parent)            { create(:category) }
    let(:parent_snapshot)   { parent.snapshots.for_month(Date.current).first }
    let(:transaction)       { build(:transaction, subcategory: category, budget: category.budget, amount: 1000) }

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
end
