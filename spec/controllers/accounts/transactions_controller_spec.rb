# frozen_string_literal: true

require "rails_helper"

describe Accounts::TransactionsController do
  describe "#index" do
    context "with an account" do
      let(:account)      { create(:account, budget: budget) }
      let(:budget)       { create(:budget) }
      let!(:transaction) { create(:transaction, account: account) }

      before do
        create(:transaction, budget: budget)

        get :index, params: { budget_id: budget.id, account_id: account.id }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:index) }

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the account" do
        expect(assigns(:account)).to eq(account)
      end

      it "assigns only transactions for the requested account" do
        expect(assigns(:grouped_transactions)).to eq(
          transaction.date => [transaction]
        )
      end
    end

    context "when hiding reconciled transactions" do
      let(:account)      { create(:account, budget: budget) }
      let(:budget)       { create(:budget) }
      let!(:transaction) { create(:transaction, account: account, date: Date.new(2026, 3, 15)) }

      before do
        create(:transaction, account: account, status: :reconciled, date: Date.new(2026, 3, 12))
        budget.settings.update(hide_reconciled: "1")

        get :index, params: { budget_id: budget.id, account_id: account.id }
      end

      it "excludes reconciled transactions" do
        expect(assigns(:grouped_transactions)).to eq(
          transaction.date => [transaction]
        )
      end
    end

    context "with an invalid budget" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :index, params: { budget_id: 0, account_id: 0 } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with an invalid account" do
      let(:budget) { create(:budget) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :index, params: { budget_id: budget.id, account_id: 0 } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
