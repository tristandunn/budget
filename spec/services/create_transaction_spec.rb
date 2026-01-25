# frozen_string_literal: true

require "rails_helper"

describe CreateTransaction do
  describe ".call" do
    context "with an account and subcategory" do
      let(:account)              { create(:account, balance: 10_000) }
      let(:subcategory)          { create(:category, :subcategory) }
      let(:subcategory_snapshot) { subcategory.snapshots.for_month(Date.current).first }
      let(:category_snapshot)    { subcategory.parent.snapshots.for_month(Date.current).first }

      let(:transaction) do
        build(:transaction, account:     account,
                            subcategory: subcategory,
                            budget:      subcategory.budget,
                            amount:      1000)
      end

      it "increments the category snapshot amount_used" do
        expect { described_class.call(transaction: transaction) }
          .to change { category_snapshot.reload.amount_used }.by(1000)
      end

      it "increments the subcategory snapshot amount_used" do
        expect { described_class.call(transaction: transaction) }
          .to change { subcategory_snapshot.reload.amount_used }.by(1000)
      end

      it "decrements the account balance by the transaction amount" do
        expect { described_class.call(transaction: transaction) }
          .to change { account.reload.balance }.from(10_000).to(9_000)
      end

      it "saves the transaction" do
        expect { described_class.call(transaction: transaction) }
          .to change(transaction, :persisted?).from(false).to(true)
      end
    end
  end
end
