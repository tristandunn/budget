# frozen_string_literal: true

require "rails_helper"

describe SuspendTransaction do
  describe ".call" do
    subject(:suspend) { described_class.call(attributes: new_attributes, transaction: transaction) }

    let(:account)        { create(:account, balance: 10_000) }
    let(:amount)         { 1000 }
    let(:new_attributes) { { date: 1.month.from_now.to_date, frequency: "monthly" } }
    let(:subcategory)    { create(:category, :subcategory) }

    let(:transaction) do
      build(:transaction, account:     account,
                          budget:      subcategory.budget,
                          subcategory: subcategory,
                          amount:      amount)
    end

    before do
      CreateTransaction.call(transaction: transaction)
    end

    context "with a positive amount" do
      it "decrements the account balance" do
        expect { suspend }.to change { account.reload.balance }.from(11_000).to(10_000)
      end

      it "restores the amount used in the category snapshot" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { suspend }.to change { snapshot.reload.amount_used }.by(1000)
      end

      it "restores the amount used in the subcategory snapshot" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { suspend }.to change { snapshot.reload.amount_used }.by(1000)
      end

      it "does not change the amount assigned in the category snapshot" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { suspend }.not_to(change { snapshot.reload.amount_assigned })
      end

      it "does not change the amount assigned in the subcategory snapshot" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { suspend }.not_to(change { snapshot.reload.amount_assigned })
      end

      it "does not change available to assign" do
        expect { suspend }.not_to(change { transaction.budget.reload.available_to_assign })
      end

      it "updates the transaction with the new attributes" do
        suspend

        expect(transaction.reload).to have_attributes(
          date:      1.month.from_now.to_date,
          frequency: "monthly",
          status:    "upcoming"
        )
      end
    end

    context "with a negative amount" do
      let(:amount) { -1000 }

      it "increments the account balance" do
        expect { suspend }.to change { account.reload.balance }.from(9_000).to(10_000)
      end

      it "decrements the amount used in the category snapshot" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { suspend }.to change { snapshot.reload.amount_used }.by(-1000)
      end

      it "decrements the amount used in the subcategory snapshot" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { suspend }.to change { snapshot.reload.amount_used }.by(-1000)
      end

      it "does not change available to assign" do
        expect { suspend }.not_to(change { transaction.budget.reload.available_to_assign })
      end

      it "updates the transaction with the new attributes" do
        suspend

        expect(transaction.reload).to have_attributes(
          date:      1.month.from_now.to_date,
          frequency: "monthly",
          status:    "upcoming"
        )
      end
    end

    context "with an inflow transaction" do
      let(:amount)      { 5000 }
      let(:subcategory) { create(:category, :inflow_subcategory) }

      it "decrements the account balance" do
        expect { suspend }.to change { account.reload.balance }.from(15_000).to(10_000)
      end

      it "decrements available to assign on the budget" do
        expect { suspend }.to change { transaction.budget.reload.available_to_assign }.by(-5000)
      end

      it "does not touch category snapshots" do
        expect { suspend }.not_to change(CategorySnapshot, :count).from(0)
      end

      it "updates the transaction with the new attributes" do
        suspend

        expect(transaction.reload).to have_attributes(
          date:      1.month.from_now.to_date,
          frequency: "monthly",
          status:    "upcoming"
        )
      end
    end

    context "when changing the amount" do
      let(:new_attributes) { { amount: 5000, date: 1.month.from_now.to_date, frequency: "monthly" } }

      it "decrements the account balance by the previous amount" do
        expect { suspend }.to change { account.reload.balance }.from(11_000).to(10_000)
      end

      it "restores the amount used in the category snapshot by the previous amount" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { suspend }.to change { snapshot.reload.amount_used }.by(1000)
      end

      it "restores the amount used in the subcategory snapshot by the previous amount" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { suspend }.to change { snapshot.reload.amount_used }.by(1000)
      end

      it "updates the transaction with the new amount" do
        suspend

        expect(transaction.reload).to have_attributes(amount: 5000, status: "upcoming")
      end
    end

    context "when changing the amount on an inflow transaction" do
      let(:amount)         { 5000 }
      let(:new_attributes) { { amount: 2500, date: 1.month.from_now.to_date, frequency: "monthly" } }
      let(:subcategory)    { create(:category, :inflow_subcategory) }

      it "decrements the account balance by the previous amount" do
        expect { suspend }.to change { account.reload.balance }.from(15_000).to(10_000)
      end

      it "decrements available to assign by the previous amount" do
        expect { suspend }.to change { transaction.budget.reload.available_to_assign }.from(5000).to(0)
      end

      it "updates the transaction with the new amount" do
        suspend

        expect(transaction.reload).to have_attributes(amount: 2500, status: "upcoming")
      end
    end

    context "when updating the transaction fails" do
      let(:amount) { -1000 }

      before do
        allow(transaction).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "does not change the account balance" do
        expect { suspend }
          .to raise_error(ActiveRecord::RecordInvalid)
          .and(not_change { account.reload.balance })
      end

      it "does not change the amount used in the category snapshot" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { suspend }
          .to raise_error(ActiveRecord::RecordInvalid)
          .and(not_change { snapshot.reload.amount_used })
      end

      it "does not change the amount used in the subcategory snapshot" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { suspend }
          .to raise_error(ActiveRecord::RecordInvalid)
          .and(not_change { snapshot.reload.amount_used })
      end
    end

    context "when updating an inflow transaction fails" do
      let(:amount)      { 5000 }
      let(:subcategory) { create(:category, :inflow_subcategory) }

      before do
        allow(transaction).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "does not change the account balance" do
        expect { suspend }
          .to raise_error(ActiveRecord::RecordInvalid)
          .and(not_change { account.reload.balance })
      end

      it "does not change available to assign on the budget" do
        expect { suspend }
          .to raise_error(ActiveRecord::RecordInvalid)
          .and(not_change { transaction.budget.reload.available_to_assign })
      end
    end

    context "without a frequency" do
      let(:new_attributes) { { date: 1.month.from_now.to_date, frequency: nil } }

      it "decrements the account balance" do
        expect { suspend }.to change { account.reload.balance }.from(11_000).to(10_000)
      end

      it "restores the amount used in the category snapshot" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { suspend }.to change { snapshot.reload.amount_used }.by(1000)
      end

      it "restores the amount used in the subcategory snapshot" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { suspend }.to change { snapshot.reload.amount_used }.by(1000)
      end

      it "updates the transaction with the new attributes" do
        suspend

        expect(transaction.reload).to have_attributes(
          date:      1.month.from_now.to_date,
          frequency: nil,
          status:    "upcoming"
        )
      end
    end
  end
end
