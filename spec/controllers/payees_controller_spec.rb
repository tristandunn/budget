# frozen_string_literal: true

require "rails_helper"

describe PayeesController do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
  end

  it { is_expected.to be_a(ApplicationController) }

  describe "#index" do
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
    let(:payee) { create(:payee, budget: budget, name: "Old Name") }

    context "when valid with the html format" do
      let(:form) { instance_double(PayeeForm, update: true) }

      before do
        allow(PayeeForm).to receive(:new).and_return(form)

        patch :update, params: { budget_id: budget.id, id: payee.id,
                                 payee_form: { name: "New Name" } }
      end

      it { is_expected.to redirect_to(budget_payees_path(budget)) }
      it { is_expected.to respond_with(:see_other) }

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

  describe "#defaults" do
    let(:payee) { create(:payee, budget: budget) }

    context "when the payee belongs to the budget" do
      let(:defaults) do
        {
          account_id:                "1",
          memo:                      "Coffee.",
          subcategory_id:            "2",
          suggested_subcategory_ids: ["2"]
        }
      end

      before do
        allow(FindPayeeDefaults).to receive(:call).and_return(defaults)

        get :defaults, params: { budget_id: budget.id, id: payee.id }
      end

      it { is_expected.to respond_with(:ok) }

      it "calls the defaults service with the payee" do
        expect(FindPayeeDefaults).to have_received(:call).with(payee: payee)
      end

      it "renders the defaults as JSON" do
        expect(response.parsed_body).to eq(defaults.deep_stringify_keys)
      end
    end

    context "when the payee belongs to a different budget" do
      let(:other_budget) { create(:budget) }
      let(:other_payee)  { create(:payee, budget: other_budget) }

      it "raises a record not found error" do
        expect do
          get :defaults, params: { budget_id: budget.id, id: other_payee.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
