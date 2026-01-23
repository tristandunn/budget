# frozen_string_literal: true

require "rails_helper"

describe TransactionsController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#new" do
    let(:budget)      { create(:budget) }
    let(:subcategory) { create(:category, :subcategory, budget: budget) }

    before do
      get :new, params: { budget_id: budget.id, subcategory_id: subcategory.id }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:new) }

    it "assigns a form" do
      expect(assigns(:form)).to be_a(TransactionForm)
        .and(have_attributes(budget: budget, category: subcategory))
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
          subcategory_id:   subcategory.id,
          transaction_form: { amount: 100 }
        }
      end

      it { is_expected.to redirect_to(budget_url(budget)) }

      it "creates a transaction" do
        expect(transaction).to be_a(Transaction)
          .and(be_persisted)
          .and(have_attributes(amount: 10_000, budget: budget, category: subcategory))
      end
    end

    context "when not created successfully" do
      let(:budget)      { create(:budget) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        post :create, params: {
          budget_id:        budget.id,
          subcategory_id:   subcategory.id,
          transaction_form: { amount: nil }
        }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:new) }

      it "assigns a form" do
        expect(assigns(:form)).to be_a(TransactionForm)
          .and(have_attributes(budget: budget, category: subcategory))
      end

      it "does not create a transaction" do
        expect(Transaction.count).to eq(0)
      end
    end
  end
end
