# frozen_string_literal: true

require "rails_helper"

describe UpdateTransaction do
  describe ".call" do
    subject(:update) { described_class.call(attributes: attributes, transaction: transaction) }

    let(:account)     { transaction.account }
    let(:subcategory) { create(:category, :subcategory) }

    let(:transaction) do
      create(:transaction, budget: subcategory.budget, subcategory: subcategory, amount: -1000)
    end

    context "when changing amount only" do
      let(:attributes) { { amount: -2000 } }

      it "updates the transaction amount" do
        update

        expect(transaction.reload.amount).to eq(-2000)
      end

      it "adjusts the account balance" do
        expect { update }.to change { account.reload.balance }.by(-1000)
      end

      it "adjusts the category snapshot amount used" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(1000)
      end

      it "adjusts the subcategory snapshot amount used" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(1000)
      end
    end

    context "when changing amount on an inflow transaction" do
      let(:attributes)         { { amount: 3000 } }
      let(:inflow_subcategory) { create(:category, :inflow_subcategory, budget: subcategory.budget) }

      let(:transaction) do
        create(:transaction, budget:      subcategory.budget,
                             subcategory: inflow_subcategory,
                             amount:      1000)
      end

      it "adjusts available to assign by the delta" do
        expect { update }.to change { subcategory.budget.reload.available_to_assign }.by(2000)
      end
    end

    context "when changing amount sign on the same subcategory" do
      let(:attributes) { { amount: 500 } }

      it "reverses the old category snapshot amount used" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(-1000)
      end

      it "applies the new category snapshot amount assigned" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_assigned }.by(500)
      end
    end

    context "when changing subcategory with a positive amount" do
      let(:attributes)      { { subcategory: new_subcategory } }
      let(:new_subcategory) { create(:category, :subcategory, budget: subcategory.budget) }

      let(:transaction) do
        create(:transaction, budget: subcategory.budget, subcategory: subcategory, amount: 1000)
      end

      it "reverses the old subcategory snapshot amount assigned" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_assigned }.by(-1000)
      end

      it "applies the new subcategory snapshot amount assigned" do
        snapshot = new_subcategory.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_assigned }.by(1000)
      end
    end

    context "when changing a positive amount" do
      let(:attributes) { { amount: 2000 } }

      let(:transaction) do
        create(:transaction, budget: subcategory.budget, subcategory: subcategory, amount: 1000)
      end

      it "adjusts the category snapshot amount assigned" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_assigned }.by(1000)
      end
    end

    context "when changing account" do
      let(:attributes)  { { account: new_account } }
      let(:new_account) { create(:account, budget: subcategory.budget) }

      it "restores the old account balance" do
        expect { update }.to change { account.reload.balance }.by(1000)
      end

      it "decrements the new account balance" do
        expect { update }.to change { new_account.reload.balance }.by(-1000)
      end
    end

    context "when changing subcategory" do
      let(:attributes)      { { subcategory: new_subcategory } }
      let(:new_subcategory) { create(:category, :subcategory, budget: subcategory.budget) }

      it "reverses the old category snapshot amount used" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(-1000)
      end

      it "applies the new category snapshot amount used" do
        snapshot = new_subcategory.parent.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(1000)
      end

      it "reverses the old subcategory snapshot amount used" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(-1000)
      end

      it "applies the new subcategory snapshot amount used" do
        snapshot = new_subcategory.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(1000)
      end
    end

    context "when changing from non-inflow to inflow" do
      let(:attributes)         { { subcategory: inflow_subcategory, amount: 1000 } }
      let(:inflow_subcategory) { create(:category, :inflow_subcategory, budget: subcategory.budget) }

      it "reverses the old category snapshot amount used" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(-1000)
      end

      it "increments available to assign" do
        expect { update }.to change { subcategory.budget.reload.available_to_assign }.by(1000)
      end
    end

    context "when changing from inflow to non-inflow" do
      let(:attributes)         { { subcategory: subcategory, amount: -500 } }
      let(:inflow_subcategory) { create(:category, :inflow_subcategory, budget: subcategory.budget) }

      let(:transaction) do
        create(:transaction, budget:      subcategory.budget,
                             subcategory: inflow_subcategory,
                             amount:      5000)
      end

      it "reverses the available to assign" do
        expect { update }.to change { subcategory.budget.reload.available_to_assign }.by(-5000)
      end

      it "applies the new subcategory snapshot amount used" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(500)
      end
    end

    context "when changing date to a different month" do
      let(:attributes) { { date: Date.new(2026, 2, 15) } }

      before do
        create(:category_snapshot, category:        subcategory.parent,
                                   amount_assigned: 0,
                                   amount_used:     0,
                                   date:            Date.new(2026, 2, 1))
        create(:category_snapshot, category:        subcategory,
                                   amount_assigned: 0,
                                   amount_used:     0,
                                   date:            Date.new(2026, 2, 1))
      end

      it "reverses the old month's category snapshot amount used" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(-1000)
      end

      it "applies the new month's category snapshot amount used" do
        snapshot = subcategory.parent.snapshots.for_month(Date.new(2026, 2, 15)).first

        expect { update }.to change { snapshot.reload.amount_used }.by(1000)
      end
    end

    context "when changing payee and memo only" do
      let(:attributes) { { payee: "New Payee", memo: "New Memo" } }

      it "updates the payee" do
        update

        expect(transaction.reload.payee).to eq("New Payee")
      end

      it "updates the memo" do
        update

        expect(transaction.reload.memo).to eq("New Memo")
      end

      it "does not change the account balance" do
        expect { update }.not_to(change { account.reload.balance })
      end

      it "does not change the category snapshot amount used" do
        snapshot = subcategory.parent.snapshots.for_month(transaction.date).first

        expect { update }.not_to(change { snapshot.reload.amount_used })
      end
    end

    context "when changing multiple fields at once" do
      let(:attributes) do
        {
          account:     create(:account, budget: subcategory.budget),
          amount:      -3000,
          subcategory: create(:category, :subcategory, budget: subcategory.budget),
          payee:       "New Payee"
        }
      end

      it "updates the payee" do
        update

        expect(transaction.reload.payee).to eq("New Payee")
      end

      it "restores the old account balance" do
        expect { update }.to change { account.reload.balance }.by(1000)
      end

      it "decrements the new account balance" do
        new_account = attributes[:account]

        expect { update }.to change { new_account.reload.balance }.by(-3000)
      end

      it "reverses the old subcategory snapshot amount used" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(-1000)
      end

      it "applies the new subcategory snapshot amount used" do
        snapshot = attributes[:subcategory].snapshots.for_month(transaction.date).first

        expect { update }.to change { snapshot.reload.amount_used }.by(3000)
      end
    end
  end
end
