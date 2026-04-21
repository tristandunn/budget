# frozen_string_literal: true

require "rails_helper"

describe AccountsController do
  describe "#index" do
    context "with a budget" do
      let(:budget) { create(:budget) }

      before do
        create(:account, budget: budget)
        create(:account, :credit, budget: budget)

        get :index, params: { budget_id: budget.id }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:index) }

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the cash accounts" do
        expect(assigns(:cash_accounts)).to contain_exactly(
          be_a(Account).and(have_attributes(budget: budget, credit: false))
        )
      end

      it "assigns the credit accounts" do
        expect(assigns(:credit_accounts)).to contain_exactly(
          be_a(Account).and(have_attributes(budget: budget, credit: true))
        )
      end
    end

    context "without a budget" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :index, params: { budget_id: 0 } }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
