# frozen_string_literal: true

require "rails_helper"

describe DestroyTransaction do
  describe ".call" do
    let(:account)              { create(:account, balance: 10_000) }
    let(:category_snapshot)    { subcategory.parent.snapshots.for_month(transaction.date).first }
    let(:subcategory_snapshot) { subcategory.snapshots.for_month(transaction.date).first }

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
        expect { described_class.call(transaction: transaction) }
          .to change { account.reload.balance }.from(11_000).to(10_000)
      end

      it "decrements the amount assigned in the category snapshot" do
        expect { described_class.call(transaction: transaction) }
          .to change { category_snapshot.reload.amount_assigned }.by(-1000)
      end

      it "decrements the amount assigned in the subcategory snapshot" do
        expect { described_class.call(transaction: transaction) }
          .to change { subcategory_snapshot.reload.amount_assigned }.by(-1000)
      end

      it "does not change available to assign" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "destroys the transaction" do
        described_class.call(transaction: transaction)

        expect(Transaction.exists?(transaction.id)).to be(false)
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
        expect { described_class.call(transaction: transaction) }
          .to change { account.reload.balance }.from(9_000).to(10_000)
      end

      it "decrements the amount used in the category snapshot" do
        expect { described_class.call(transaction: transaction) }
          .to change { category_snapshot.reload.amount_used }.by(-1000)
      end

      it "decrements the amount used in the subcategory snapshot" do
        expect { described_class.call(transaction: transaction) }
          .to change { subcategory_snapshot.reload.amount_used }.by(-1000)
      end

      it "does not change available to assign" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "destroys the transaction" do
        described_class.call(transaction: transaction)

        expect(Transaction.exists?(transaction.id)).to be(false)
      end
    end

    context "with an upcoming recurring transaction" do
      let(:subcategory) { create(:category, :subcategory) }

      let(:transaction) do
        create(:transaction, :recurring,
               account:     account,
               subcategory: subcategory,
               budget:      subcategory.budget,
               amount:      1000)
      end

      it "does not change the account balance" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { account.reload.balance })
      end

      it "does not change available to assign" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "destroys the transaction" do
        described_class.call(transaction: transaction)

        expect(Transaction.exists?(transaction.id)).to be(false)
      end
    end

    context "with an upcoming non-recurring transaction" do
      let(:subcategory) { create(:category, :subcategory) }

      let(:transaction) do
        create(:transaction, :upcoming,
               account:     account,
               subcategory: subcategory,
               budget:      subcategory.budget,
               amount:      1000)
      end

      it "does not change the account balance" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { account.reload.balance })
      end

      it "does not change available to assign" do
        expect { described_class.call(transaction: transaction) }
          .not_to(change { subcategory.budget.reload.available_to_assign })
      end

      it "destroys the transaction" do
        described_class.call(transaction: transaction)

        expect(Transaction.exists?(transaction.id)).to be(false)
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
        expect { described_class.call(transaction: transaction) }
          .to change { account.reload.balance }.from(15_000).to(10_000)
      end

      it "decrements available to assign on the budget" do
        expect { described_class.call(transaction: transaction) }
          .to change { subcategory.budget.reload.available_to_assign }.by(-5000)
      end

      it "does not touch category snapshots" do
        described_class.call(transaction: transaction)

        expect(CategorySnapshot.count).to eq(0)
      end

      it "destroys the transaction" do
        described_class.call(transaction: transaction)

        expect(Transaction.exists?(transaction.id)).to be(false)
      end
    end
  end
end
