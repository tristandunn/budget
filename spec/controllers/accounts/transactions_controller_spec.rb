# frozen_string_literal: true

require "rails_helper"

describe Accounts::TransactionsController do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
  end

  describe "#index" do
    context "with an account" do
      let(:account)      { create(:account, budget: budget) }
      let!(:transaction) { create(:transaction, account: account) }
      let!(:upcoming)    { create(:transaction, :upcoming, account: account) }

      before do
        create(:transaction, budget: budget)
        create(:transaction, budget: budget, date: 1.week.from_now)
        create(:transaction, account: account, date: 32.days.ago.to_date)

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

      it "assigns current transactions for the requested account limited to the previous 31 days" do
        expect(assigns(:current_transactions)).to eq([transaction])
      end

      it "assigns scheduled transactions for the requested account" do
        expect(assigns(:scheduled_transactions)).to eq([upcoming])
      end
    end

    context "when hiding reconciled transactions" do
      let(:account)      { create(:account, budget: budget) }
      let!(:transaction) { create(:transaction, account: account, date: 5.days.ago.to_date) }

      before do
        create(:transaction, account: account, status: :reconciled, date: 10.days.ago.to_date)
        budget.settings.update(hide_reconciled: "1")

        get :index, params: { budget_id: budget.id, account_id: account.id }
      end

      it "excludes reconciled transactions" do
        expect(assigns(:current_transactions)).to eq([transaction])
      end
    end

    context "with an invalid budget" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :index, params: { budget_id: 0, account_id: 0 } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with an invalid account" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :index, params: { budget_id: budget.id, account_id: 0 } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
