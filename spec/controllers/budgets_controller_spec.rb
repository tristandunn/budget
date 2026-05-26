# frozen_string_literal: true

require "rails_helper"

describe BudgetsController do
  describe "#index" do
    context "when signed in with a budget" do
      let!(:budget) { create(:budget) }

      before do
        sign_in_for(budget)

        get :index
      end

      it { is_expected.to redirect_to(budget_path(budget)) }
    end

    context "when signed in without a budget" do
      before do
        sign_in
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :index }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when signed out" do
      before do
        get :index
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end

  describe "#show" do
    context "when signed in with a budget belonging to the current user" do
      let(:budget)   { category.budget }
      let(:category) { create(:category) }

      before do
        sign_in_for(budget)

        get :show, params: { id: budget.id }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:show) }

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the budget snapshot" do
        expect(assigns(:budget_snapshot)).to be_a(BudgetSnapshot)
      end
    end

    context "when signed in with a budget belonging to another user" do
      let(:budget) { create(:budget) }

      before do
        sign_in
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :show, params: { id: budget.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when signed out" do
      let(:budget) { create(:budget) }

      before do
        get :show, params: { id: budget.id }
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end
end
