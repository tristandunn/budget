# frozen_string_literal: true

require "rails_helper"

describe ActivateTransaction do
  describe ".call" do
    let(:account)              { create(:account, balance: 10_000) }
    let(:category_snapshot)    { subcategory.parent.snapshots.for_month(transaction.date).first }
    let(:subcategory_snapshot) { subcategory.snapshots.for_month(transaction.date).first }

    def new_attributes
      {
        account:     transaction.account,
        amount:      transaction.amount,
        date:        transaction.date,
        frequency:   nil,
        memo:        transaction.memo,
        payee:       transaction.payee,
        subcategory: transaction.subcategory
      }
    end

    context "with a positive amount" do
      let(:subcategory) { create(:category, :subcategory) }

      let(:transaction) do
        create(:transaction, :recurring,
               account:     account,
               subcategory: subcategory,
               budget:      subcategory.budget,
               amount:      1000)
      end

      it "increments the account balance" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { account.reload.balance }.from(10_000).to(11_000)
      end

      it "decrements the amount used in the category snapshot" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(category_snapshot.amount_used).to eq(-1000)
      end

      it "decrements the amount used in the subcategory snapshot" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(subcategory_snapshot.amount_used).to eq(-1000)
      end

      it "does not change the amount assigned in the category snapshot" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(category_snapshot.amount_assigned).to eq(0)
      end

      it "does not change the amount assigned in the subcategory snapshot" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(subcategory_snapshot.amount_assigned).to eq(0)
      end

      it "does not change available to assign" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "updates the transaction with the new attributes" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(transaction.reload).to have_attributes(frequency: nil, status: "pending")
      end
    end

    context "with a negative amount" do
      let(:subcategory) { create(:category, :subcategory) }

      let(:transaction) do
        create(:transaction, :recurring,
               account:     account,
               subcategory: subcategory,
               budget:      subcategory.budget,
               amount:      -1000)
      end

      it "decrements the account balance" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { account.reload.balance }.from(10_000).to(9_000)
      end

      it "increments the amount used in the category snapshot" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(category_snapshot.amount_used).to eq(1000)
      end

      it "increments the amount used in the subcategory snapshot" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(subcategory_snapshot.amount_used).to eq(1000)
      end

      it "does not change available to assign" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "updates the transaction with the new attributes" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(transaction.reload).to have_attributes(frequency: nil, status: "pending")
      end
    end

    context "with an inflow transaction" do
      let(:subcategory) { create(:category, :inflow_subcategory) }

      let(:transaction) do
        create(:transaction, :recurring,
               account:     account,
               subcategory: subcategory,
               budget:      subcategory.budget,
               amount:      5000)
      end

      it "increments the account balance" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { account.reload.balance }.from(10_000).to(15_000)
      end

      it "increments available to assign on the budget" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { subcategory.budget.reload.available_to_assign }.by(5000)
      end

      it "does not touch category snapshots" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .not_to change(CategorySnapshot, :count).from(0)
      end

      it "updates the transaction with the new attributes" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(transaction.reload).to have_attributes(frequency: nil, status: "pending")
      end
    end

    context "without existing snapshots" do
      let(:subcategory) do
        parent = create(:category, with_snapshot: false)

        create(:category, parent: parent, budget: parent.budget, with_snapshot: false)
      end

      let(:transaction) do
        create(:transaction, :recurring,
               account:     account,
               subcategory: subcategory,
               budget:      subcategory.budget,
               amount:      -500)
      end

      it "increments the account balance" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { account.reload.balance }.from(10_000).to(9_500)
      end

      it "creates the category snapshot" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { subcategory.parent.snapshots.count }.from(0).to(1)
      end

      it "creates the subcategory snapshot" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .to change { subcategory.snapshots.count }.from(0).to(1)
      end

      it "increments the amount used in the category snapshot" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(category_snapshot.amount_used).to eq(500)
      end

      it "increments the amount used in the subcategory snapshot" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(subcategory_snapshot.amount_used).to eq(500)
      end

      it "does not change available to assign" do
        expect { described_class.call(attributes: new_attributes, transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "updates the transaction with the new attributes" do
        described_class.call(attributes: new_attributes, transaction: transaction)

        expect(transaction.reload).to have_attributes(frequency: nil, status: "pending")
      end
    end
  end
end
