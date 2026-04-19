# frozen_string_literal: true

require "rails_helper"

describe SuspendTransaction do
  describe ".call" do
    let(:account)              { create(:account, balance: 10_000) }
    let(:category_snapshot)    { subcategory.parent.snapshots.for_month(transaction.date).first }
    let(:subcategory_snapshot) { subcategory.snapshots.for_month(transaction.date).first }

    def new_attributes
      {
        account:     transaction.account,
        amount:      transaction.amount,
        date:        1.month.from_now.to_date,
        frequency:   "monthly",
        memo:        transaction.memo,
        payee:       transaction.payee,
        subcategory: transaction.subcategory
      }
    end

    context "with a positive amount" do
      let(:subcategory) { create(:category, :subcategory) }

      let(:transaction) do
        build(:transaction, account:     account,
                            subcategory: subcategory,
                            budget:      subcategory.budget,
                            amount:      1000)
      end

      before do
        CreateTransaction.call(transaction: transaction)
      end

      it "decrements the account balance" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { account.reload.balance }.from(11_000).to(10_000)
      end

      it "decrements the amount assigned in the category snapshot" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { category_snapshot.reload.amount_assigned }.by(-1000)
      end

      it "decrements the amount assigned in the subcategory snapshot" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { subcategory_snapshot.reload.amount_assigned }.by(-1000)
      end

      it "does not change available to assign" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "updates the transaction with the new attributes" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(transaction.reload).to have_attributes(
          date:      1.month.from_now.to_date,
          frequency: "monthly",
          status:    "upcoming"
        )
      end
    end

    context "with a negative amount" do
      let(:subcategory) { create(:category, :subcategory) }

      let(:transaction) do
        build(:transaction, account:     account,
                            subcategory: subcategory,
                            budget:      subcategory.budget,
                            amount:      -1000)
      end

      before do
        CreateTransaction.call(transaction: transaction)
      end

      it "increments the account balance" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { account.reload.balance }.from(9_000).to(10_000)
      end

      it "decrements the amount used in the category snapshot" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { category_snapshot.reload.amount_used }.by(-1000)
      end

      it "decrements the amount used in the subcategory snapshot" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { subcategory_snapshot.reload.amount_used }.by(-1000)
      end

      it "does not change available to assign" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "updates the transaction with the new attributes" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(transaction.reload).to have_attributes(
          date:      1.month.from_now.to_date,
          frequency: "monthly",
          status:    "upcoming"
        )
      end
    end

    context "with an inflow transaction" do
      let(:subcategory) { create(:category, :inflow_subcategory) }

      let(:transaction) do
        build(:transaction, account:     account,
                            subcategory: subcategory,
                            budget:      subcategory.budget,
                            amount:      5000)
      end

      before do
        CreateTransaction.call(transaction: transaction)
      end

      it "decrements the account balance" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { account.reload.balance }.from(15_000).to(10_000)
      end

      it "decrements available to assign on the budget" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { subcategory.budget.reload.available_to_assign }.by(-5000)
      end

      it "does not touch category snapshots" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(CategorySnapshot.count).to eq(0)
      end

      it "updates the transaction with the new attributes" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(transaction.reload).to have_attributes(
          date:      1.month.from_now.to_date,
          frequency: "monthly",
          status:    "upcoming"
        )
      end
    end
  end
end
