# frozen_string_literal: true

require "rails_helper"

describe TransfersController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#new" do
    let(:budget)    { create(:budget) }
    let!(:checking) { create(:account, budget: budget, name: "Checking") }
    let!(:savings)  { create(:account, budget: budget, name: "Savings") }

    before do
      get :new, params: { budget_id: budget.id }
    end

    it { is_expected.to render_template(:new) }
    it { is_expected.to respond_with(200) }

    it "assigns the budget" do
      expect(assigns(:budget)).to eq(budget)
    end

    it "assigns the budget accounts" do
      expect(assigns(:accounts)).to eq([checking, savings])
    end

    it "assigns a transfer form" do
      expect(assigns(:form)).to be_a(TransferForm)
    end
  end

  describe "#create" do
    let(:budget) { create(:budget) }

    before do
      allow(TransferForm).to receive(:new).and_return(form)
    end

    context "when valid" do
      let(:form)           { instance_double(TransferForm, save: true) }
      let(:from_account)   { create(:account, budget: budget, name: "Checking") }
      let(:to_account)     { create(:account, budget: budget, name: "Savings") }

      before do
        post :create, params: {
          budget_id:     budget.id,
          transfer_form: {
            amount:          "50.00",
            date:            "2026-04-15",
            from_account_id: from_account.id,
            memo:            "Move savings",
            to_account_id:   to_account.id
          }
        }
      end

      it { is_expected.to redirect_to(budget_transactions_path(budget)) }
      it { is_expected.to respond_with(:see_other) }

      it "initializes the form with the resolved attributes" do
        expect(TransferForm).to have_received(:new).with(
          amount:       "50.00",
          budget:       budget,
          date:         "2026-04-15",
          from_account: from_account,
          memo:         "Move savings",
          to_account:   to_account
        )
      end

      it "saves the form" do
        expect(form).to have_received(:save)
      end
    end

    context "when invalid" do
      let(:form)           { instance_double(TransferForm, save: false) }
      let(:from_account)   { create(:account, budget: budget, name: "Checking") }
      let(:to_account)     { create(:account, budget: budget, name: "Savings") }

      before do
        post :create, params: {
          budget_id:     budget.id,
          transfer_form: {
            amount:          "50.00",
            date:            "2026-04-15",
            from_account_id: from_account.id,
            memo:            "Move savings",
            to_account_id:   to_account.id
          }
        }
      end

      it { is_expected.to render_template(:new) }
      it { is_expected.to respond_with(:unprocessable_content) }

      it "assigns the form" do
        expect(assigns(:form)).to eq(form)
      end

      it "assigns the budget accounts" do
        expect(assigns(:accounts)).to include(from_account, to_account)
      end
    end
  end
end
