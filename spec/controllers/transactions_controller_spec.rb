# frozen_string_literal: true

require "rails_helper"

describe TransactionsController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#index" do
    let(:budget)  { create(:budget) }
    let!(:newer)  { create(:transaction, budget: budget, date: Date.new(2026, 3, 15)) }
    let!(:older)  { create(:transaction, budget: budget, date: Date.new(2026, 3, 10)) }

    before do
      create(:transaction)

      get :index, params: { budget_id: budget.id }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:index) }

    it "assigns the budget" do
      expect(assigns(:budget)).to eq(budget)
    end

    it "assigns transactions grouped by date in reverse chronological order" do
      expect(assigns(:grouped_transactions)).to eq(
        newer.date => [newer],
        older.date => [older]
      )
    end
  end

  describe "#new" do
    let(:budget) { create(:budget) }
    let(:form)   { instance_double(TransactionForm) }

    before do
      allow(TransactionForm).to receive(:new).and_return(form)

      get :new, params: { budget_id: budget.id }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:new) }

    it "initializes the form with the budget" do
      expect(TransactionForm).to have_received(:new).with(budget: budget)
    end

    it "assigns the budget accounts" do
      expect(assigns(:accounts)).to eq(budget.accounts)
    end

    it "assigns a transaction form" do
      expect(assigns(:form)).to eq(form)
    end

    it "assigns the budget subcategories" do
      expect(assigns(:subcategories)).to eq(budget.subcategories)
    end
  end

  describe "#create" do
    context "when valid" do
      let(:account)     { create(:account, budget: budget) }
      let(:budget)      { create(:budget) }
      let(:form)        { instance_double(TransactionForm, save: true) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      let(:expected_parameters) do
        {
          account:     account,
          amount:      "100",
          budget:      budget,
          date:        "2026-03-18",
          memo:        "A memo",
          payee:       "Test Payee",
          subcategory: subcategory
        }
      end

      before do
        allow(TransactionForm).to receive(:new).and_return(form)

        post :create, params: {
          budget_id:        budget.id,
          transaction_form: {
            account_id:     account.id,
            amount:         "100",
            date:           "2026-03-18",
            memo:           "A memo",
            payee:          "Test Payee",
            subcategory_id: subcategory.id
          }
        }
      end

      it { is_expected.to redirect_to(budget_url(budget)) }

      it "initializes the form with transaction parameters" do
        expect(TransactionForm).to have_received(:new).with(expected_parameters)
      end

      it "saves the form" do
        expect(form).to have_received(:save)
      end
    end

    context "when invalid" do
      let(:account)     { create(:account) }
      let(:budget)      { account.budget }
      let(:form)        { instance_double(TransactionForm, save: false) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      let(:expected_parameters) do
        {
          account:     account,
          amount:      "invalid",
          budget:      budget,
          date:        "2026-03-18",
          memo:        "A memo",
          payee:       "Test Payee",
          subcategory: subcategory
        }
      end

      before do
        allow(TransactionForm).to receive(:new).and_return(form)

        post :create, params: {
          budget_id:        budget.id,
          transaction_form: {
            account_id:     account.id,
            amount:         "invalid",
            date:           "2026-03-18",
            memo:           "A memo",
            payee:          "Test Payee",
            subcategory_id: subcategory.id
          }
        }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:new) }

      it "initializes the form" do
        expect(TransactionForm).to have_received(:new).with(expected_parameters)
      end

      it "assigns the budget accounts" do
        expect(assigns(:accounts)).to eq(budget.accounts)
      end

      it "assigns a transaction form" do
        expect(assigns(:form)).to eq(form)
      end

      it "assigns the budget subcategories" do
        expect(assigns(:subcategories)).to eq(budget.subcategories)
      end
    end
  end
end
