# frozen_string_literal: true

require "rails_helper"

describe PayeesController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#index" do
    let(:budget) { create(:budget) }

    let!(:apple) { create(:payee, budget: budget, name: "Apple") }
    let!(:zebra) { create(:payee, budget: budget, name: "Zebra") }

    before do
      create(:payee, name: "Other Budget Payee")

      get :index, params: { budget_id: budget.id }
    end

    it { is_expected.to respond_with(:ok) }
    it { is_expected.to render_template(:index) }

    it "assigns the budget" do
      expect(assigns(:budget)).to eq(budget)
    end

    it "assigns the budget's payees ordered by name" do
      expect(assigns(:payees)).to eq([apple, zebra])
    end
  end

  describe "#edit" do
    let(:budget) { create(:budget) }
    let(:form)   { instance_double(PayeeForm) }
    let(:payee)  { create(:payee, budget: budget) }

    before do
      allow(PayeeForm).to receive(:from).and_return(form)

      get :edit, params: { budget_id: budget.id, id: payee.id }
    end

    it { is_expected.to respond_with(:ok) }
    it { is_expected.to render_template(:edit) }

    it "assigns the budget" do
      expect(assigns(:budget)).to eq(budget)
    end

    it "assigns the payee" do
      expect(assigns(:payee)).to eq(payee)
    end

    it "initializes the form from the payee" do
      expect(PayeeForm).to have_received(:from).with(payee: payee)
    end

    it "assigns the form" do
      expect(assigns(:form)).to eq(form)
    end
  end

  describe "#update" do
    let(:budget) { create(:budget) }
    let(:payee)  { create(:payee, budget: budget, name: "Old Name") }

    context "when valid with the html format" do
      let(:form) { instance_double(PayeeForm, update: true) }

      before do
        allow(PayeeForm).to receive(:new).and_return(form)

        patch :update, params: { budget_id: budget.id, id: payee.id,
                                 payee_form: { name: "New Name" } }
      end

      it { is_expected.to redirect_to(budget_payees_path(budget)) }

      it "initializes the form with the payee and parameters" do
        expect(PayeeForm).to have_received(:new).with(payee: payee, name: "New Name")
      end

      it "updates the payee" do
        expect(form).to have_received(:update).with(no_args)
      end
    end

    context "when valid with the Turbo stream format" do
      let(:form) { instance_double(PayeeForm, update: true) }

      let!(:other_payee) { create(:payee, budget: budget, name: "Apple") }

      before do
        allow(PayeeForm).to receive(:new).and_return(form)

        patch :update,
              params: { budget_id: budget.id, id: payee.id,
                        payee_form: { name: "New Name" } },
              format: :turbo_stream
      end

      it { is_expected.to respond_with(:ok) }
      it { is_expected.to render_template(:update) }

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the payee" do
        expect(assigns(:payee)).to eq(payee)
      end

      it "assigns the form" do
        expect(assigns(:form)).to eq(form)
      end

      it "assigns the budget's payees ordered by name" do
        expect(assigns(:payees)).to eq([other_payee, payee])
      end
    end

    context "when invalid with the HTML format" do
      let(:form) { instance_double(PayeeForm, update: nil) }

      before do
        allow(PayeeForm).to receive(:new).and_return(form)

        patch :update, params: { budget_id: budget.id, id: payee.id,
                                 payee_form: { name: "" } }
      end

      it { is_expected.to respond_with(:unprocessable_content) }
      it { is_expected.to render_template(:edit) }

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the payee" do
        expect(assigns(:payee)).to eq(payee)
      end

      it "assigns the form" do
        expect(assigns(:form)).to eq(form)
      end
    end

    context "when invalid with the Turbo stream format" do
      let(:form) { instance_double(PayeeForm, update: nil) }

      before do
        allow(PayeeForm).to receive(:new).and_return(form)

        patch :update,
              params: { budget_id: budget.id, id: payee.id,
                        payee_form: { name: "" } },
              format: :turbo_stream
      end

      it { is_expected.to respond_with(:unprocessable_content) }
      it { is_expected.to render_template(:edit) }
    end

    context "when the payee belongs to a different budget" do
      let(:other_budget) { create(:budget) }
      let(:other_payee)  { create(:payee, budget: other_budget) }

      it "raises a record not found error" do
        expect do
          patch :update, params: { budget_id: budget.id, id: other_payee.id,
                                   payee_form: { name: "New Name" } }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#previous_category" do
    let(:budget) { create(:budget) }
    let(:payee)  { create(:payee, budget: budget) }

    context "when the payee belongs to the budget" do
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        create(:transaction, budget: budget, payee: payee, subcategory: subcategory)

        get :previous_category, params: { budget_id: budget.id, id: payee.id }
      end

      it { is_expected.to respond_with(:ok) }

      it "returns the previous subcategory id" do
        expect(response.parsed_body).to eq("subcategory_id" => subcategory.id.to_s)
      end
    end

    context "when the payee belongs to a different budget" do
      let(:other_budget) { create(:budget) }
      let(:other_payee)  { create(:payee, budget: other_budget) }

      it "raises a record not found error" do
        expect do
          get :previous_category, params: { budget_id: budget.id, id: other_payee.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
