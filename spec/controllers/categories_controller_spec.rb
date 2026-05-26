# frozen_string_literal: true

require "rails_helper"

describe CategoriesController do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
  end

  it { is_expected.to be_a(ApplicationController) }

  describe "#show" do
    let(:subcategory) { create(:category, :subcategory, budget: budget) }

    context "when on the first month" do
      before do
        get :show, params: { budget_id: budget.id, id: subcategory.id }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:show) }

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

    context "when not on the first month" do
      before do
        create(:category_snapshot,
               budget:          budget,
               category:        subcategory,
               amount_assigned: 50_000,
               amount_used:     20_000,
               date:            1.month.ago.beginning_of_month)

        get :show, params: { budget_id: budget.id, id: subcategory.id }
      end

      it "assigns the previous budget snapshot" do
        expect(assigns(:previous_budget_snapshot)).to be_a(BudgetSnapshot)
      end
    end
  end

  describe "#edit" do
    let(:form)        { instance_double(CategoryForm) }
    let(:subcategory) { create(:category, :subcategory, budget: budget) }

    before do
      allow(CategoryForm).to receive(:from).and_return(form)

      get :edit, params: { budget_id: budget.id, id: subcategory.id }
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
      expect(CategoryForm).to have_received(:from).with(category: subcategory)
    end

    it "assigns the form" do
      expect(assigns(:form)).to eq(form)
    end
  end

  describe "#update" do
    context "when valid with the html format" do
      let(:form)        { instance_double(CategoryForm, update: true) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        allow(CategoryForm).to receive(:new).and_return(form)

        patch :update, params: {
          budget_id:     budget.id,
          id:            subcategory.id,
          category_form: { name: "New Name" }
        }
      end

      it "initializes the form with the category and parameters" do
        expect(CategoryForm).to have_received(:new).with(category: subcategory, name: "New Name")
      end

      it "updates the category" do
        expect(form).to have_received(:update).with(no_args)
      end

      it "redirects to the budget" do
        expect(response).to redirect_to(budget_url(budget))
      end
    end

    context "when valid with the turbo_stream format" do
      let(:form)        { instance_double(CategoryForm, update: true) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        allow(CategoryForm).to receive(:new).and_return(form)

        patch :update,
              params: {
                budget_id:     budget.id,
                id:            subcategory.id,
                category_form: { name: "New Name" }
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
      let(:form)        { instance_double(CategoryForm, update: nil) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        allow(CategoryForm).to receive(:new).and_return(form)

        patch :update, params: {
          budget_id:     budget.id,
          id:            subcategory.id,
          category_form: { name: "" }
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
      let(:form)        { instance_double(CategoryForm, update: nil) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        allow(CategoryForm).to receive(:new).and_return(form)

        patch :update,
              params: {
                budget_id:     budget.id,
                id:            subcategory.id,
                category_form: { name: "" }
              },
              format: :turbo_stream
      end

      it { is_expected.to respond_with(422) }
      it { is_expected.to render_template(:edit) }
    end
  end
end
