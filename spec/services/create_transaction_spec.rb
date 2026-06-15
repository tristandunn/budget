# frozen_string_literal: true

require "rails_helper"

describe CreateTransaction do
  describe ".call" do
    let(:account)                { create(:account, balance: 10_000) }
    let(:category_snapshot)      { subcategory.parent.snapshots.for_month(transaction.date).first }
    let(:subcategory)            { create(:category, :subcategory) }
    let(:subcategory_snapshot)   { subcategory.snapshots.for_month(transaction.date).first }

    context "with a positive amount" do
      let(:transaction) do
        build(:transaction, account:     account,
                            subcategory: subcategory,
                            budget:      subcategory.budget,
                            amount:      1000)
      end

      it "increments the account balance" do
        expect { described_class.call(transaction: transaction) }
          .to change { account.reload.balance }.from(10_000).to(11_000)
      end

      it "decrements the amount used in the category snapshot" do
        expect { described_class.call(transaction: transaction) }
          .to change { category_snapshot.reload.amount_used }.by(-1000)
      end

      it "decrements the amount used in the subcategory snapshot" do
        expect { described_class.call(transaction: transaction) }
          .to change { subcategory_snapshot.reload.amount_used }.by(-1000)
      end

      it "does not change the amount assigned in the category snapshot" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { category_snapshot.reload.amount_assigned })
      end

      it "does not change the amount assigned in the subcategory snapshot" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { subcategory_snapshot.reload.amount_assigned })
      end

      it "does not change available to assign" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "saves the transaction" do
        expect { described_class.call(transaction: transaction) }
          .to change(transaction, :persisted?).from(false).to(true)
      end
    end

    context "with a positive amount in a monthly savings category" do
      let(:subcategory) do
        parent = create(:category, with_snapshot: false)

        create(:category, :with_monthly_savings_target,
               parent: parent, budget: parent.budget, with_snapshot: false)
      end

      let(:transaction) do
        build(:transaction, account:     account,
                            subcategory: subcategory,
                            budget:      subcategory.budget,
                            amount:      20_000)
      end

      before do
        create(:category_snapshot, category:        subcategory.parent,
                                   amount_assigned: 0,
                                   amount_used:     0)
        create(:category_snapshot, category:        subcategory,
                                   amount_assigned: 0,
                                   amount_used:     0)
      end

      it "does not change the amount assigned in the subcategory snapshot" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { subcategory_snapshot.reload.amount_assigned })
      end

      it "does not fund the savings target" do
        described_class.call(transaction: transaction)

        progress = TargetProgress.new(category: subcategory,
                                      rollover: 0,
                                      snapshot: subcategory_snapshot.reload)

        expect(progress.funded_amount).to eq(0)
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

      it "increments the account balance" do
        expect { described_class.call(transaction: transaction) }
          .to change { account.reload.balance }.from(10_000).to(15_000)
      end

      it "increments available to assign on the budget" do
        expect { described_class.call(transaction: transaction) }
          .to change { subcategory.budget.reload.available_to_assign }.by(5000)
      end

      it "does not touch category snapshots" do
        expect { described_class.call(transaction: transaction) }
          .not_to change(CategorySnapshot, :count).from(0)
      end

      it "saves the transaction" do
        expect { described_class.call(transaction: transaction) }
          .to change(transaction, :persisted?).from(false).to(true)
      end
    end

    context "with a negative amount" do
      let(:transaction) do
        build(:transaction, account:     account,
                            subcategory: subcategory,
                            budget:      subcategory.budget,
                            amount:      -1000)
      end

      it "decrements the account balance" do
        expect { described_class.call(transaction: transaction) }
          .to change { account.reload.balance }.from(10_000).to(9_000)
      end

      it "increments the amount used in the category snapshot" do
        expect { described_class.call(transaction: transaction) }
          .to change { category_snapshot.reload.amount_used }.by(1000)
      end

      it "increments the amount used in the subcategory snapshot" do
        expect { described_class.call(transaction: transaction) }
          .to change { subcategory_snapshot.reload.amount_used }.by(1000)
      end

      it "does not change available to assign" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "saves the transaction" do
        expect { described_class.call(transaction: transaction) }
          .to change(transaction, :persisted?).from(false).to(true)
      end
    end

    context "without existing snapshots" do
      let(:subcategory) do
        parent = create(:category, with_snapshot: false)

        create(:category, parent: parent, budget: parent.budget, with_snapshot: false)
      end

      let(:transaction) do
        build(:transaction, account:     account,
                            subcategory: subcategory,
                            budget:      subcategory.budget,
                            amount:      -500)
      end

      it "decrements the account balance" do
        expect { described_class.call(transaction: transaction) }
          .to change { account.reload.balance }.from(10_000).to(9_500)
      end

      it "creates the category snapshot" do
        expect { described_class.call(transaction: transaction) }
          .to change { subcategory.parent.snapshots.count }.from(0).to(1)
      end

      it "creates the subcategory snapshot" do
        expect { described_class.call(transaction: transaction) }
          .to change { subcategory.snapshots.count }.from(0).to(1)
      end

      it "increments the amount used in the category snapshot" do
        described_class.call(transaction: transaction)

        expect(category_snapshot.reload.amount_used).to eq(500)
      end

      it "increments the amount used in the subcategory snapshot" do
        described_class.call(transaction: transaction)

        expect(subcategory_snapshot.reload.amount_used).to eq(500)
      end

      it "does not change available to assign" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "saves the transaction" do
        expect { described_class.call(transaction: transaction) }
          .to change(transaction, :persisted?).from(false).to(true)
      end
    end

    context "with a backdated transaction" do
      let(:subcategory) { create(:category, :subcategory, with_snapshot: false) }

      let(:transaction) do
        build(:transaction, account:     account,
                            subcategory: subcategory,
                            budget:      subcategory.budget,
                            amount:      -500,
                            date:        Date.new(2026, 1, 15))
      end

      before do
        create(:category_snapshot, category:        subcategory.parent,
                                   amount_assigned: 0,
                                   amount_used:     0,
                                   date:            transaction.date.beginning_of_month)
        create(:category_snapshot, category:        subcategory,
                                   amount_assigned: 0,
                                   amount_used:     0,
                                   date:            transaction.date.beginning_of_month)
      end

      it "decrements the account balance" do
        expect { described_class.call(transaction: transaction) }
          .to change { account.reload.balance }.from(10_000).to(9_500)
      end

      it "uses the transaction date for snapshot lookup" do
        snapshot = subcategory.snapshots.for_month(transaction.date).first

        expect { described_class.call(transaction: transaction) }
          .to change { snapshot.reload.amount_used }.by(500)
      end

      it "does not change available to assign" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "saves the transaction" do
        expect { described_class.call(transaction: transaction) }
          .to change(transaction, :persisted?).from(false).to(true)
      end
    end
  end
end
