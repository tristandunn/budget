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

    context "with a JSON request and accounts in the budget" do
      let!(:amex)     { create(:account, :credit, budget: budget, name: "Amex") }
      let(:budget)    { create(:budget) }
      let!(:checking) { create(:account, budget: budget, name: "Checking") }
      let!(:savings)  { create(:account, budget: budget, name: "Savings") }
      let!(:visa)     { create(:account, :credit, budget: budget, name: "Visa") }

      before do
        get :index, params: { budget_id: budget.id, format: :json }
      end

      it { is_expected.to respond_with(200) }

      it "orders cash accounts alphabetically before credit accounts alphabetically" do
        expect(response.parsed_body).to eq(
          [
            { "id" => checking.id, "name" => "Checking", "credit" => false },
            { "id" => savings.id,  "name" => "Savings",  "credit" => false },
            { "id" => amex.id,     "name" => "Amex",     "credit" => true  },
            { "id" => visa.id,     "name" => "Visa",     "credit" => true  }
          ]
        )
      end
    end

    context "with a JSON request and no accounts" do
      let(:budget) { create(:budget) }

      before do
        get :index, params: { budget_id: budget.id, format: :json }
      end

      it { is_expected.to respond_with(200) }

      it "returns an empty array" do
        expect(response.parsed_body).to eq([])
      end
    end

    context "with a JSON request scoped to the budget" do
      let(:budget)       { create(:budget) }
      let(:other_budget) { create(:budget) }

      before do
        create(:account, budget: other_budget)

        get :index, params: { budget_id: budget.id, format: :json }
      end

      it { is_expected.to respond_with(200) }

      it "only returns accounts belonging to the budget" do
        expect(response.parsed_body).to eq([])
      end
    end

    context "without a budget" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :index, params: { budget_id: 0 } }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises an ActiveRecord::RecordNotFound error for JSON requests" do
        expect do
          get :index, params: { budget_id: 0, format: :json }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
