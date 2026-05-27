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
    let(:budget) { create(:budget) }

    context "when signed in with a budget belonging to the current user" do
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

    context "when signed in with a year and month before the snapshot range" do
      before do
        sign_in_for(budget)

        get :show, params: { id: budget.id, year: "2020", month: "1" }
      end

      it { is_expected.to respond_with(302) }

      it "redirects to the first month of the snapshot range" do
        expect(response).to redirect_to(
          month_budget_path(budget, year: Date.current.year, month: Date.current.month)
        )
      end
    end

    context "when signed in with a year and month after the snapshot range" do
      let(:next_month) { Date.current.next_month.beginning_of_month }

      before do
        sign_in_for(budget)

        get :show, params: { id: budget.id, year: "2099", month: "12" }
      end

      it { is_expected.to respond_with(302) }

      it "redirects to the last month of the snapshot range" do
        expect(response).to redirect_to(
          month_budget_path(budget, year: next_month.year, month: next_month.month)
        )
      end
    end

    context "when signed in with an out-of-bounds month parameter" do
      before do
        sign_in_for(budget)

        get :show, params: { id: budget.id, year: "2026", month: "13" }
      end

      it { is_expected.to respond_with(302) }

      it "redirects to the current month" do
        expect(response).to redirect_to(
          month_budget_path(budget, year: Date.current.year, month: Date.current.month)
        )
      end
    end

    context "when signed in with a non-numeric month parameter" do
      before do
        sign_in_for(budget)

        get :show, params: { id: budget.id, year: "2026", month: "foo" }
      end

      it { is_expected.to respond_with(302) }

      it "redirects to the current month" do
        expect(response).to redirect_to(
          month_budget_path(budget, year: Date.current.year, month: Date.current.month)
        )
      end
    end

    context "when signed in with valid year and month parameters" do
      before do
        sign_in_for(budget)

        get :show, params: { id: budget.id, year: Date.current.year.to_s, month: Date.current.month.to_s }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:show) }
    end

    context "when signed in with a budget belonging to another user" do
      before do
        sign_in
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :show, params: { id: budget.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when signed out" do
      before do
        get :show, params: { id: budget.id }
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end
end
