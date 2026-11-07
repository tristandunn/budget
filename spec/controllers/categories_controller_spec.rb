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

    context "without a month and year" do
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

      it "assigns the budget snapshot for the current month" do
        expect(assigns(:budget_snapshot)).to have_attributes(date: Date.current.beginning_of_month)
      end
    end

    context "with a month and year" do
      let(:requested_date) { 1.month.ago.beginning_of_month }

      before do
        create(:category_snapshot, budget: budget, category: subcategory, date: 3.months.ago.beginning_of_month)

        get :show, params: {
          budget_id: budget.id,
          id:        subcategory.id,
          month:     requested_date.month,
          year:      requested_date.year
        }
      end

      it "assigns the budget snapshot for the requested month" do
        expect(assigns(:budget_snapshot)).to have_attributes(date: requested_date)
      end
    end

    context "with an inflow category" do
      let(:inflow) { create(:category, :inflow_subcategory, budget: budget) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :show, params: { budget_id: budget.id, id: inflow.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a category belonging to a different budget" do
      let(:other_subcategory) { create(:category, :subcategory) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :show, params: { budget_id: budget.id, id: other_subcategory.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
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

    context "with an inflow category" do
      let(:inflow) { create(:category, :inflow_subcategory, budget: budget) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :edit, params: { budget_id: budget.id, id: inflow.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a category belonging to a different budget" do
      let(:other_subcategory) { create(:category, :subcategory) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :edit, params: { budget_id: budget.id, id: other_subcategory.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
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

      it { is_expected.to respond_with(:see_other) }
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

      it "assigns the budget snapshot for the current month" do
        expect(assigns(:budget_snapshot)).to have_attributes(date: Date.current.beginning_of_month)
      end
    end

    context "when valid with the turbo_stream format and a month and year" do
      let(:requested_date) { 1.month.ago.beginning_of_month }

      let(:form)        { instance_double(CategoryForm, update: true) }
      let(:subcategory) do
        create(:category, :subcategory, budget: budget).tap do |record|
          create(:category_snapshot, budget: budget, category: record, date: 3.months.ago.beginning_of_month)
        end
      end

      before do
        allow(CategoryForm).to receive(:new).and_return(form)

        patch :update,
              params: {
                budget_id:     budget.id,
                id:            subcategory.id,
                category_form: { name: "New Name" },
                month:         requested_date.month,
                year:          requested_date.year
              },
              format: :turbo_stream
      end

      it "assigns the budget snapshot for the requested month" do
        expect(assigns(:budget_snapshot)).to have_attributes(date: requested_date)
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

    context "with an inflow category" do
      let(:inflow) { create(:category, :inflow_subcategory, budget: budget) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect do
          patch :update, params: {
            budget_id:     budget.id,
            id:            inflow.id,
            category_form: { name: "Paychecks" }
          }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a category belonging to a different budget" do
      let(:other_subcategory) { create(:category, :subcategory) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect do
          patch :update, params: {
            budget_id:     budget.id,
            id:            other_subcategory.id,
            category_form: { name: "New Name" }
          }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#summary" do
    let(:subcategories) { create_list(:category, 2, :subcategory, budget: budget, with_snapshot: false) }
    let(:summary)       { instance_double(CategorySummary) }

    before do
      allow(CategorySummary).to receive(:new).and_return(summary)
    end

    context "without a month and year" do
      before do
        get :summary, params: {
          budget_id: budget.id,
          ids:       subcategories.map(&:id)
        }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:summary) }

      it "assigns the budget snapshot for the current month" do
        expect(assigns(:budget_snapshot)).to have_attributes(date: Date.current.beginning_of_month)
      end

      it "initializes the summary with the displayed budget snapshot" do
        expect(CategorySummary).to have_received(:new).with(
          budget,
          budget_snapshot: assigns(:budget_snapshot),
          ids:             subcategories.map { |subcategory| subcategory.id.to_s }
        )
      end

      it "assigns the summary" do
        expect(assigns(:summary)).to eq(summary)
      end
    end

    context "with a month and year" do
      let(:requested_date) { 1.month.ago.beginning_of_month }

      before do
        create(:category_snapshot, budget: budget, category: subcategories.first, date: 3.months.ago.beginning_of_month)

        get :summary, params: {
          budget_id: budget.id,
          ids:       subcategories.map(&:id),
          month:     requested_date.month,
          year:      requested_date.year
        }
      end

      it "initializes the summary with the requested month's budget snapshot" do
        expect(CategorySummary).to have_received(:new).with(
          budget,
          budget_snapshot: have_attributes(date: requested_date),
          ids:             subcategories.map { |subcategory| subcategory.id.to_s }
        )
      end
    end
  end
end
