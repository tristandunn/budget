# frozen_string_literal: true

require "rails_helper"

describe AssignmentsController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#edit" do
    let(:budget)      { subcategory.budget }
    let(:form)        { instance_double(AssignmentForm) }
    let(:subcategory) { create(:category, :subcategory) }

    before do
      allow(AssignmentForm).to receive(:new).and_return(form)

      get :edit, params: { budget_id: budget.id, category_id: subcategory.id }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:edit) }

    it "initializes the form with the budget, subcategory, and date" do
      expect(AssignmentForm).to have_received(:new)
        .with(budget: budget, subcategory: subcategory, date: Date.current.beginning_of_month)
    end

    it "assigns the budget" do
      expect(assigns(:budget)).to eq(budget)
    end

    it "assigns the subcategory" do
      expect(assigns(:subcategory)).to eq(subcategory)
    end

    it "assigns the category snapshot" do
      expect(assigns(:subcategory_snapshot)).to eq(subcategory.snapshots.for_month(Date.current).first)
    end

    it "assigns the form" do
      expect(assigns(:form)).to eq(form)
    end

    context "with year and month parameters" do
      let(:date) { 2.months.ago.to_date.beginning_of_month }

      before do
        allow(AssignmentForm).to receive(:new).and_return(form)

        get :edit, params: {
          budget_id:   budget.id,
          category_id: subcategory.id,
          month:       date.month,
          year:        date.year
        }
      end

      it "initializes the form with the parsed date" do
        expect(AssignmentForm).to have_received(:new)
          .with(budget: budget, subcategory: subcategory, date: date)
      end
    end
  end

  describe "#update" do
    context "when valid" do
      let(:budget)      { subcategory.budget }
      let(:form)        { instance_double(AssignmentForm, save: true) }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        allow(AssignmentForm).to receive(:new).and_return(form)

        patch :update, params: {
          budget_id:       budget.id,
          category_id:     subcategory.id,
          assignment_form: { amount: "100.00" }
        }
      end

      it "initializes the form with the parameters" do
        expect(AssignmentForm).to have_received(:new)
          .with(amount: "100.00", budget: budget, date: Date.current.beginning_of_month, subcategory: subcategory)
      end

      it "saves the form" do
        expect(form).to have_received(:save)
      end

      it "redirects to the budget" do
        expect(response).to redirect_to(
          month_budget_url(budget, month: Date.current.month, year: Date.current.year)
        )
      end
    end

    context "with valid year and month parameters" do
      let(:budget)      { subcategory.budget }
      let(:date)        { 2.months.ago.to_date.beginning_of_month }
      let(:form)        { instance_double(AssignmentForm, save: true) }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        allow(AssignmentForm).to receive(:new).and_return(form)

        patch :update, params: {
          budget_id:       budget.id,
          category_id:     subcategory.id,
          year:            date.year,
          month:           date.month,
          assignment_form: { amount: "100.00" }
        }
      end

      it "redirects to the budget" do
        expect(response).to redirect_to(
          month_budget_url(budget, month: date.month, year: date.year)
        )
      end

      it "initializes the form with the parsed date" do
        expect(AssignmentForm).to have_received(:new)
          .with(amount: "100.00", budget: budget, date: date, subcategory: subcategory)
      end
    end

    context "when invalid" do
      let(:budget)      { subcategory.budget }
      let(:form)        { instance_double(AssignmentForm, save: false) }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        allow(AssignmentForm).to receive(:new).and_return(form)

        patch :update, params: {
          budget_id:       budget.id,
          category_id:     subcategory.id,
          assignment_form: { amount: "invalid" }
        }
      end

      it { is_expected.to respond_with(422) }
      it { is_expected.to render_template(:edit) }

      it "initializes the form" do
        expect(AssignmentForm).to have_received(:new)
          .with(amount: "invalid", budget: budget, date: Date.current.beginning_of_month, subcategory: subcategory)
      end

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the subcategory" do
        expect(assigns(:subcategory)).to eq(subcategory)
      end

      it "assigns the category snapshot" do
        expect(assigns(:subcategory_snapshot)).to eq(subcategory.snapshots.for_month(Date.current).first)
      end

      it "assigns the form" do
        expect(assigns(:form)).to eq(form)
      end
    end
  end
end
