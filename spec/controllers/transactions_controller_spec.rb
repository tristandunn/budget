# frozen_string_literal: true

require "rails_helper"

describe TransactionsController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#new" do
    let(:budget) { create(:budget) }

    before do
      get :new, params: { budget_id: budget.id }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:new) }

    it "assigns a form" do
      expect(assigns(:form)).to be_a(TransactionForm)
        .and(have_attributes(budget: budget))
    end

    it "assigns subcategories" do
      expect(assigns(:subcategories)).to eq(budget.subcategories)
    end
  end

  describe "#create" do
    context "when created successfully" do
      let(:budget)      { create(:budget) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }
      let(:form)        { assigns(:form) }
      let(:transaction) { form.transaction }

      before do
        post :create, params: {
          budget_id:        budget.id,
          transaction_form: { amount: 100, subcategory_id: subcategory.id }
        }
      end

      it { is_expected.to redirect_to(budget_url(budget)) }

      it "creates a transaction" do
        expect(transaction).to be_a(Transaction)
          .and(be_persisted)
          .and(have_attributes(amount: 10_000, budget: budget, category: subcategory))
      end

      it "assigns subcategories" do
        expect(assigns(:subcategories)).to eq(budget.subcategories)
      end
    end

    context "with no amount" do
      let(:budget)      { create(:budget) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        post :create, params: {
          budget_id:        budget.id,
          transaction_form: { amount: nil, subcategory_id: subcategory.id }
        }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:new) }

      it "assigns a form without an amount" do
        expect(assigns(:form)).to be_a(TransactionForm)
          .and(have_attributes(amount: nil, budget: budget, category: subcategory))
      end

      it "assigns subcategories" do
        expect(assigns(:subcategories)).to eq(budget.subcategories)
      end

      it "does not create a transaction" do
        expect(Transaction.count).to eq(0)
      end
    end

    context "with no subcategory" do
      let(:budget) { create(:budget) }

      before do
        post :create, params: {
          budget_id:        budget.id,
          transaction_form: { amount: 100, subcategory_id: "" }
        }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:new) }

      it "assigns a form without category" do
        expect(assigns(:form)).to be_a(TransactionForm)
          .and(have_attributes(budget: budget, category: nil))
      end

      it "assigns subcategories" do
        expect(assigns(:subcategories)).to eq(budget.subcategories)
      end

      it "does not create a transaction" do
        expect(Transaction.count).to eq(0)
      end
    end
  end
end
