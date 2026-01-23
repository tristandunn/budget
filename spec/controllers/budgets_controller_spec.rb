# frozen_string_literal: true

require "rails_helper"

describe BudgetsController do
  describe "#index" do
    context "with a budget" do
      let!(:budget) { create(:budget) }

      before do
        get :index
      end

      it { is_expected.to redirect_to(budget_path(budget)) }
    end

    context "without a budget" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :index }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#show" do
    context "with a budget" do
      let(:budget)   { category.budget }
      let(:category) { create(:category) }

      before do
        get :show, params: { id: budget.id }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:show) }

      it "assigns the date" do
        expect(assigns(:date)).to eq(Date.current.beginning_of_month)
      end

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the category snapshots" do
        expect(assigns(:snapshots)).to eq(budget.category_snapshots.index_by(&:category_id))
      end
    end

    context "without a budget" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :show, params: { id: 0 } }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
