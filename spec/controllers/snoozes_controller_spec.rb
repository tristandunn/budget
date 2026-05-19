# frozen_string_literal: true

require "rails_helper"

describe SnoozesController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#create" do
    let(:budget)      { subcategory.budget }
    let(:subcategory) { create(:category, :subcategory, :with_monthly_spending_target, with_snapshot: false) }

    context "without an existing snapshot for the month" do
      before do
        post :create, params: { budget_id: budget.id, category_id: subcategory.id }, format: :turbo_stream
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:create) }

      it "creates a snoozed snapshot for the displayed month" do
        snapshot = subcategory.snapshots.for_month(Date.current).first

        expect(snapshot).to be_snoozed
      end

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the category" do
        expect(assigns(:category)).to eq(subcategory)
      end

      it "assigns the budget snapshot" do
        expect(assigns(:budget_snapshot)).to be_a(BudgetSnapshot)
      end
    end

    context "with an existing snapshot for the month" do
      let!(:snapshot) do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 100,
               amount_used:     50,
               date:            Date.current.beginning_of_month)
      end

      before do
        post :create, params: { budget_id: budget.id, category_id: subcategory.id }, format: :turbo_stream
      end

      it "snoozes the existing snapshot" do
        expect(snapshot.reload).to be_snoozed
      end

      it "preserves the assigned amount" do
        expect(snapshot.reload.amount_assigned).to eq(100)
      end
    end

    context "when already snoozed" do
      before do
        create(:category_snapshot,
               budget:   budget,
               category: subcategory,
               date:     Date.current.beginning_of_month,
               metadata: { "snoozed" => true })

        post :create, params: { budget_id: budget.id, category_id: subcategory.id }, format: :turbo_stream
      end

      it { is_expected.to respond_with(200) }

      it "remains snoozed" do
        expect(subcategory.snapshots.for_month(Date.current).first).to be_snoozed
      end
    end

    context "with explicit year and month parameters" do
      let(:displayed_date) { 1.month.ago.beginning_of_month }

      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 50_000,
               date:            displayed_date)

        post :create,
             params: {
               budget_id:   budget.id,
               category_id: subcategory.id,
               year:        displayed_date.year,
               month:       displayed_date.month
             },
             format: :turbo_stream
      end

      it "snoozes the snapshot for the requested month" do
        snapshot = subcategory.snapshots.for_month(displayed_date).first

        expect(snapshot).to be_snoozed
      end
    end

    context "with a category that has no target" do
      let(:subcategory) { create(:category, :subcategory, with_snapshot: false) }

      it "raises a record not found error" do
        expect do
          post :create, params: { budget_id: budget.id, category_id: subcategory.id }, format: :turbo_stream
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with the html format" do
      before do
        post :create,
             params: {
               budget_id:   budget.id,
               category_id: subcategory.id,
               year:        Date.current.year,
               month:       Date.current.month
             }
      end

      it "snoozes the snapshot for the displayed month" do
        snapshot = subcategory.snapshots.for_month(Date.current).first

        expect(snapshot).to be_snoozed
      end

      it "redirects to the budget for the displayed month" do
        expect(response).to redirect_to(
          month_budget_url(budget, month: Date.current.month, year: Date.current.year)
        )
      end
    end
  end

  describe "#destroy" do
    let(:budget)      { subcategory.budget }
    let(:subcategory) { create(:category, :subcategory, :with_monthly_spending_target, with_snapshot: false) }

    context "when a snoozed snapshot exists" do
      let!(:snapshot) do
        create(:category_snapshot,
               budget:   budget,
               category: subcategory,
               date:     Date.current.beginning_of_month,
               metadata: { "snoozed" => true })
      end

      before do
        delete :destroy, params: { budget_id: budget.id, category_id: subcategory.id }, format: :turbo_stream
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:destroy) }

      it "clears the snoozed flag" do
        expect(snapshot.reload).not_to be_snoozed
      end
    end

    context "when an unsnoozed snapshot already exists" do
      let!(:snapshot) do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 100,
               date:            Date.current.beginning_of_month)
      end

      before do
        delete :destroy, params: { budget_id: budget.id, category_id: subcategory.id }, format: :turbo_stream
      end

      it { is_expected.to respond_with(200) }

      it "leaves the snapshot unsnoozed" do
        expect(snapshot.reload).not_to be_snoozed
      end

      it "does not update the snapshot" do
        expect { snapshot.reload }.not_to change(snapshot, :updated_at)
      end
    end

    context "with explicit year and month parameters" do
      let(:displayed_date) { 1.month.ago.beginning_of_month }

      let!(:snapshot) do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 50_000,
               date:            displayed_date,
               metadata:        { "snoozed" => true })
      end

      before do
        delete :destroy,
               params: {
                 budget_id:   budget.id,
                 category_id: subcategory.id,
                 year:        displayed_date.year,
                 month:       displayed_date.month
               },
               format: :turbo_stream
      end

      it "clears the snoozed flag on the snapshot for the requested month" do
        expect(snapshot.reload).not_to be_snoozed
      end
    end

    context "with the html format" do
      let!(:snapshot) do
        create(:category_snapshot,
               budget:   budget,
               category: subcategory,
               date:     Date.current.beginning_of_month,
               metadata: { "snoozed" => true })
      end

      before do
        delete :destroy,
               params: {
                 budget_id:   budget.id,
                 category_id: subcategory.id,
                 year:        Date.current.year,
                 month:       Date.current.month
               }
      end

      it "clears the snoozed flag" do
        expect(snapshot.reload).not_to be_snoozed
      end

      it "redirects to the budget for the displayed month" do
        expect(response).to redirect_to(
          month_budget_url(budget, month: Date.current.month, year: Date.current.year)
        )
      end
    end
  end
end
