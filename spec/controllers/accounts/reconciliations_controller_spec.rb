# frozen_string_literal: true

require "rails_helper"

describe Accounts::ReconciliationsController do
  let(:account) { create(:account, budget: budget) }
  let(:budget)  { create(:budget) }

  before do
    sign_in_for(budget)
  end

  describe "#create" do
    context "with a cleared transaction" do
      before do
        create(:transaction, :cleared, account: account, budget: budget)

        post :create, params: { budget_id: budget.id, account_id: account.id }
      end

      it { is_expected.to redirect_to(budget_account_transactions_path(budget, account)) }
      it { is_expected.to respond_with(:see_other) }

      it "marks the transaction as reconciled" do
        expect(account.transactions.reconciled.count).to eq(1)
      end
    end

    context "with a pending transaction" do
      before do
        create(:transaction, account: account, budget: budget)

        post :create, params: { budget_id: budget.id, account_id: account.id }
      end

      it "does not reconcile the transaction" do
        expect(account.transactions.pending.count).to eq(1)
      end
    end

    context "with a cleared transaction in another account" do
      let(:other_account) { create(:account, budget: budget) }

      before do
        create(:transaction, :cleared, account: other_account, budget: budget)

        post :create, params: { budget_id: budget.id, account_id: account.id }
      end

      it "does not reconcile the transaction" do
        expect(other_account.transactions.cleared.count).to eq(1)
      end
    end

    context "with an account belonging to a different budget" do
      let(:other_account) { create(:account) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { post :create, params: { budget_id: budget.id, account_id: other_account.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
