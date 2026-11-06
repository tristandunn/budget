# frozen_string_literal: true

require "rails_helper"

describe ActivateTransaction do
  describe ".call" do
    subject(:activate) { described_class.call(attributes: new_attributes, transaction: transaction) }

    let(:account)        { create(:account, balance: 10_000) }
    let(:amount)         { 1000 }
    let(:new_attributes) { { frequency: nil } }
    let(:subcategory)    { create(:category, :subcategory) }

    let(:transaction) do
      create(:transaction, :recurring,
             account:     account,
             budget:      subcategory.budget,
             subcategory: subcategory,
             amount:      amount)
    end

    context "with a positive amount" do
      it "increments the account balance" do
        expect { activate }.to change { account.reload.balance }.from(10_000).to(11_000)
      end

      it "decrements the amount used in the category snapshot" do
        activate

        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect(snapshot.amount_used).to eq(-1000)
      end

      it "decrements the amount used in the subcategory snapshot" do
        activate

        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect(snapshot.amount_used).to eq(-1000)
      end

      it "does not change available to assign" do
        expect { activate }.not_to(change { transaction.budget.reload.available_to_assign })
      end

      it "updates the transaction with the new attributes" do
        activate

        expect(transaction.reload).to have_attributes(frequency: nil, status: "pending")
      end
    end

    context "with a negative amount" do
      let(:amount) { -1000 }

      it "decrements the account balance" do
        expect { activate }.to change { account.reload.balance }.from(10_000).to(9_000)
      end

      it "increments the amount used in the category snapshot" do
        activate

        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect(snapshot.amount_used).to eq(1000)
      end

      it "increments the amount used in the subcategory snapshot" do
        activate

        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect(snapshot.amount_used).to eq(1000)
      end

      it "does not change available to assign" do
        expect { activate }.not_to(change { transaction.budget.reload.available_to_assign })
      end

      it "updates the transaction with the new attributes" do
        activate

        expect(transaction.reload).to have_attributes(frequency: nil, status: "pending")
      end
    end

    context "with an inflow transaction" do
      let(:amount)      { 5000 }
      let(:subcategory) { create(:category, :inflow_subcategory) }

      it "increments the account balance" do
        expect { activate }.to change { account.reload.balance }.from(10_000).to(15_000)
      end

      it "increments available to assign on the budget" do
        expect { activate }.to change { transaction.budget.reload.available_to_assign }.by(5000)
      end

      it "does not touch category snapshots" do
        expect { activate }.not_to change(CategorySnapshot, :count).from(0)
      end

      it "updates the transaction with the new attributes" do
        activate

        expect(transaction.reload).to have_attributes(frequency: nil, status: "pending")
      end
    end

    context "when changing the amount and date" do
      let(:new_attributes) { { amount: 2500, date: Date.current, frequency: nil } }

      it "increments the account balance by the new amount" do
        expect { activate }.to change { account.reload.balance }.from(10_000).to(12_500)
      end

      it "decrements the amount used in the category snapshot for the new date" do
        snapshot = subcategory.parent.snapshots.for_month(Date.current).first

        expect { activate }.to change { snapshot.reload.amount_used }.by(-2500)
      end

      it "decrements the amount used in the subcategory snapshot for the new date" do
        snapshot = subcategory.snapshots.for_month(Date.current).first

        expect { activate }.to change { snapshot.reload.amount_used }.by(-2500)
      end

      it "does not change the amount assigned in the category snapshot" do
        snapshot = subcategory.parent.snapshots.for_month(Date.current).first

        expect { activate }.not_to(change { snapshot.reload.amount_assigned })
      end

      it "does not change the amount assigned in the subcategory snapshot" do
        snapshot = subcategory.snapshots.for_month(Date.current).first

        expect { activate }.not_to(change { snapshot.reload.amount_assigned })
      end

      it "does not create a snapshot for the previous date" do
        previous_date = transaction.date

        expect { activate }
          .not_to change { transaction.budget.category_snapshots.for_month(previous_date).count }.from(0)
      end

      it "updates the transaction with the new attributes" do
        activate

        expect(transaction.reload).to have_attributes(
          amount:    2500,
          date:      Date.current,
          frequency: nil,
          status:    "pending"
        )
      end
    end

    context "when changing the amount on an inflow transaction" do
      let(:amount)         { 5000 }
      let(:new_attributes) { { amount: 2500, frequency: nil } }
      let(:subcategory)    { create(:category, :inflow_subcategory) }

      it "increments the account balance by the new amount" do
        expect { activate }.to change { account.reload.balance }.from(10_000).to(12_500)
      end

      it "increments available to assign by the new amount" do
        expect { activate }.to change { transaction.budget.reload.available_to_assign }.from(0).to(2500)
      end

      it "updates the transaction with the new attributes" do
        activate

        expect(transaction.reload).to have_attributes(amount: 2500, frequency: nil, status: "pending")
      end
    end

    context "without existing snapshots" do
      let(:amount) { -500 }

      let(:subcategory) do
        parent = create(:category, with_snapshot: false)

        create(:category, parent: parent, budget: parent.budget, with_snapshot: false)
      end

      it "increments the account balance" do
        expect { activate }.to change { account.reload.balance }.from(10_000).to(9_500)
      end

      it "creates the category snapshot" do
        expect { activate }.to change { subcategory.parent.snapshots.count }.from(0).to(1)
      end

      it "creates the subcategory snapshot" do
        expect { activate }.to change { subcategory.snapshots.count }.from(0).to(1)
      end

      it "increments the amount used in the category snapshot" do
        activate

        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect(snapshot.amount_used).to eq(500)
      end

      it "increments the amount used in the subcategory snapshot" do
        activate

        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect(snapshot.amount_used).to eq(500)
      end

      it "does not change available to assign" do
        expect { activate }.not_to(change { transaction.budget.reload.available_to_assign })
      end

      it "updates the transaction with the new attributes" do
        activate

        expect(transaction.reload).to have_attributes(frequency: nil, status: "pending")
      end
    end
  end
end
