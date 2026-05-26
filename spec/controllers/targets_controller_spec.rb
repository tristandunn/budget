# frozen_string_literal: true

require "rails_helper"

describe TargetsController do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
  end

  it { is_expected.to be_a(ApplicationController) }

  describe "#edit" do
    let(:form)        { instance_double(TargetForm) }
    let(:subcategory) { create(:category, :subcategory, budget: budget) }

    before do
      allow(TargetForm).to receive(:from).and_return(form)

      get :edit, params: { budget_id: budget.id, category_id: subcategory.id }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:edit) }

    it "assigns the budget" do
      expect(assigns(:budget)).to eq(budget)
    end

    it "assigns the category" do
      expect(assigns(:category)).to eq(subcategory)
    end

    it "initializes the form from the category" do
      expect(TargetForm).to have_received(:from).with(category: subcategory)
    end

    it "assigns the form" do
      expect(assigns(:form)).to eq(form)
    end

    it "assigns the budget snapshot" do
      expect(assigns(:budget_snapshot)).to be_a(BudgetSnapshot)
    end
  end

  describe "#update" do
    let(:form_parameters) { { target_type: "monthly_spending", target_amount_input: "200.00" } }

    context "when valid with the html format" do
      let(:form)        { instance_double(TargetForm, update: true) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        allow(TargetForm).to receive(:new).and_return(form)

        patch :update, params: {
          budget_id:   budget.id,
          category_id: subcategory.id,
          target_form: form_parameters
        }
      end

      it "initializes the form with the category and parameters" do
        expect(TargetForm).to have_received(:new).with(category: subcategory, **form_parameters)
      end

      it "updates the target" do
        expect(form).to have_received(:update).with(no_args)
      end

      it "redirects to the budget for the displayed month" do
        expect(response).to redirect_to(
          month_budget_url(budget, month: Date.current.month, year: Date.current.year)
        )
      end
    end

    context "when valid with the turbo_stream format" do
      let(:form)        { instance_double(TargetForm, update: true) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        allow(TargetForm).to receive(:new).and_return(form)

        patch :update,
              params: {
                budget_id:   budget.id,
                category_id: subcategory.id,
                target_form: form_parameters
              },
              format: :turbo_stream
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:update) }

      it "assigns the budget snapshot" do
        expect(assigns(:budget_snapshot)).to be_a(BudgetSnapshot)
      end
    end

    context "when invalid with the html format" do
      let(:form)        { instance_double(TargetForm, update: nil) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        allow(TargetForm).to receive(:new).and_return(form)

        patch :update, params: {
          budget_id:   budget.id,
          category_id: subcategory.id,
          target_form: { target_type: "monthly_spending", target_amount_input: "" }
        }
      end

      it { is_expected.to respond_with(422) }
      it { is_expected.to render_template(:edit) }

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the category" do
        expect(assigns(:category)).to eq(subcategory)
      end

      it "assigns the form" do
        expect(assigns(:form)).to eq(form)
      end
    end

    context "when invalid with the turbo_stream format" do
      let(:form)        { instance_double(TargetForm, update: nil) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        allow(TargetForm).to receive(:new).and_return(form)

        patch :update,
              params: {
                budget_id:   budget.id,
                category_id: subcategory.id,
                target_form: { target_type: "monthly_spending", target_amount_input: "" }
              },
              format: :turbo_stream
      end

      it { is_expected.to respond_with(422) }
      it { is_expected.to render_template(:edit) }
    end
  end

  describe "#destroy" do
    let(:subcategory) do
      create(:category, :subcategory, budget: budget, target_type: :monthly_spending, target_amount: 200_00)
    end

    context "without a previous month" do
      before do
        delete :destroy, params: { budget_id: budget.id, category_id: subcategory.id }, format: :turbo_stream
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:destroy) }

      it "clears the target type" do
        expect(subcategory.reload.target_type).to be_nil
      end

      it "clears the target amount" do
        expect(subcategory.reload.target_amount).to be_nil
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

      it "assigns no previous budget snapshot" do
        expect(assigns(:previous_budget_snapshot)).to be_nil
      end
    end

    context "with a previous month" do
      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 50_000,
               date:            1.month.ago.beginning_of_month)

        delete :destroy, params: { budget_id: budget.id, category_id: subcategory.id }, format: :turbo_stream
      end

      it "assigns the previous budget snapshot" do
        expect(assigns(:previous_budget_snapshot)).to be_a(BudgetSnapshot)
      end
    end

    context "with the html format" do
      before do
        delete :destroy, params: { budget_id: budget.id, category_id: subcategory.id }
      end

      it "clears the target type" do
        expect(subcategory.reload.target_type).to be_nil
      end

      it "redirects to the budget for the displayed month" do
        expect(response).to redirect_to(
          month_budget_url(budget, month: Date.current.month, year: Date.current.year)
        )
      end
    end
  end
end
