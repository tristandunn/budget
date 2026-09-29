# frozen_string_literal: true

require "rails_helper"

describe SnoozesController do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
  end

  it { is_expected.to be_a(ApplicationController) }

  describe "#create" do
    let(:subcategory) do
      create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
    end

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
      let(:subcategory) { create(:category, :subcategory, budget: budget, with_snapshot: false) }

      it "raises a record not found error" do
        expect do
          post :create, params: { budget_id: budget.id, category_id: subcategory.id }, format: :turbo_stream
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a category belonging to a different budget" do
      let(:other_subcategory) { create(:category, :subcategory, :with_monthly_spending_target) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { post :create, params: { budget_id: budget.id, category_id: other_subcategory.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
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

      it { is_expected.to respond_with(:see_other) }
    end

    context "with an out-of-range month parameter" do
      it "raises a bad request error" do
        expect do
          post :create,
               params: {
                 budget_id:   budget.id,
                 category_id: subcategory.id,
                 year:        Date.current.year,
                 month:       "13"
               }
        end.to raise_error(ActionController::BadRequest)
      end
    end

    context "with an unparsable year parameter" do
      it "raises a bad request error" do
        expect do
          post :create,
               params: {
                 budget_id:   budget.id,
                 category_id: subcategory.id,
                 year:        "invalid",
                 month:       Date.current.month
               }
        end.to raise_error(ActionController::BadRequest)
      end
    end

    context "with a negative month parameter" do
      it "raises a bad request error" do
        expect do
          post :create,
               params: {
                 budget_id:   budget.id,
                 category_id: subcategory.id,
                 year:        Date.current.year,
                 month:       "-1"
               }
        end.to raise_error(ActionController::BadRequest)
      end
    end

    context "without a month parameter" do
      it "raises a bad request error" do
        expect do
          post :create,
               params: {
                 budget_id:   budget.id,
                 category_id: subcategory.id,
                 year:        Date.current.year
               }
        end.to raise_error(ActionController::BadRequest)
      end
    end

    context "with a month after the snapshot range" do
      let(:next_month) { Date.current.next_month.beginning_of_month }

      before do
        post :create,
             params: {
               budget_id:   budget.id,
               category_id: subcategory.id,
               year:        5.years.from_now.year,
               month:       1
             }
      end

      it "snoozes the snapshot for the last month of the snapshot range" do
        snapshot = subcategory.snapshots.for_month(next_month).first

        expect(snapshot).to be_snoozed
      end

      it "redirects to the budget for the last month of the snapshot range" do
        expect(response).to redirect_to(
          month_budget_url(budget, month: next_month.month, year: next_month.year)
        )
      end

      it { is_expected.to respond_with(:see_other) }
    end
  end

  describe "#destroy" do
    let(:subcategory) do
      create(:category, :subcategory, :with_monthly_spending_target, budget: budget, with_snapshot: false)
    end

    context "when a snoozed snapshot exists" do
      let!(:snapshot) do
        create(:category_snapshot,
               :snoozed,
               budget:   budget,
               category: subcategory,
               date:     Date.current.beginning_of_month)
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

    context "with a category belonging to a different budget" do
      let(:other_subcategory) { create(:category, :subcategory, :with_monthly_spending_target) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { delete :destroy, params: { budget_id: budget.id, category_id: other_subcategory.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with explicit year and month parameters" do
      let(:displayed_date) { 1.month.ago.beginning_of_month }

      let!(:snapshot) do
        create(:category_snapshot,
               :snoozed,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 50_000,
               date:            displayed_date)
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
               :snoozed,
               budget:   budget,
               category: subcategory,
               date:     Date.current.beginning_of_month)
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

      it { is_expected.to respond_with(:see_other) }
    end

    context "with an out-of-range month parameter" do
      it "raises a bad request error" do
        expect do
          delete :destroy,
                 params: {
                   budget_id:   budget.id,
                   category_id: subcategory.id,
                   year:        Date.current.year,
                   month:       "13"
                 }
        end.to raise_error(ActionController::BadRequest)
      end
    end

    context "with an unparsable year parameter" do
      it "raises a bad request error" do
        expect do
          delete :destroy,
                 params: {
                   budget_id:   budget.id,
                   category_id: subcategory.id,
                   year:        "invalid",
                   month:       Date.current.month
                 }
        end.to raise_error(ActionController::BadRequest)
      end
    end

    context "with a negative month parameter" do
      it "raises a bad request error" do
        expect do
          delete :destroy,
                 params: {
                   budget_id:   budget.id,
                   category_id: subcategory.id,
                   year:        Date.current.year,
                   month:       "-1"
                 }
        end.to raise_error(ActionController::BadRequest)
      end
    end

    context "without a month parameter" do
      it "raises a bad request error" do
        expect do
          delete :destroy,
                 params: {
                   budget_id:   budget.id,
                   category_id: subcategory.id,
                   year:        Date.current.year
                 }
        end.to raise_error(ActionController::BadRequest)
      end
    end

    context "with a month after the snapshot range" do
      let(:next_month) { Date.current.next_month.beginning_of_month }

      let!(:snapshot) do
        create(:category_snapshot,
               :snoozed,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 0,
               amount_used:     0,
               date:            next_month)
      end

      before do
        delete :destroy,
               params: {
                 budget_id:   budget.id,
                 category_id: subcategory.id,
                 year:        5.years.from_now.year,
                 month:       1
               }
      end

      it "clears the snoozed flag on the snapshot for the last month of the snapshot range" do
        expect(snapshot.reload).not_to be_snoozed
      end

      it "redirects to the budget for the last month of the snapshot range" do
        expect(response).to redirect_to(
          month_budget_url(budget, month: next_month.month, year: next_month.year)
        )
      end

      it { is_expected.to respond_with(:see_other) }
    end
  end
end
