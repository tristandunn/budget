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

    it "assigns non-inflow categories sorted by position" do
      expect(assigns(:categories)).to eq(budget.categories.reject(&:inflow?).sort_by(&:position))
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

      it { is_expected.to respond_with(422) }
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

      it "assigns non-inflow categories sorted by position" do
        expect(assigns(:categories)).to eq(budget.categories.reject(&:inflow?).sort_by(&:position))
      end
    end
  end

  describe "#edit" do
    let(:budget)      { create(:budget) }
    let(:form)        { instance_double(TransactionForm) }
    let(:transaction) { create(:transaction, budget: budget) }

    before do
      allow(TransactionForm).to receive(:from).and_return(form)

      request.headers["HTTP_REFERER"] = "/previous-page"

      get :edit, params: { budget_id: budget.id, id: transaction.id }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:edit) }

    it "assigns the budget accounts" do
      expect(assigns(:accounts)).to eq(budget.accounts)
    end

    it "assigns non-inflow categories sorted by position" do
      expect(assigns(:categories)).to eq(budget.categories.reject(&:inflow?).sort_by(&:position))
    end

    it "assigns the transaction" do
      expect(assigns(:transaction)).to eq(transaction)
    end

    it "assigns a transaction form" do
      expect(assigns(:form)).to eq(form)
    end

    it "initializes the form with the transaction" do
      expect(TransactionForm).to have_received(:from).with(transaction: transaction)
    end

    it "stores the referer in the session" do
      expect(session[:return_to]).to eq("/previous-page")
    end
  end

  describe "#update" do
    let(:account)     { create(:account, budget: budget) }
    let(:budget)      { create(:budget) }
    let(:subcategory) { create(:category, :subcategory, budget: budget) }
    let(:transaction) { create(:transaction, budget: budget) }

    before do
      allow(TransactionForm).to receive(:new).and_return(form)
    end

    context "when valid" do
      let(:form) { instance_double(TransactionForm, update: true) }

      before do
        patch :update, params: {
          budget_id:        budget.id,
          id:               transaction.id,
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

      it { is_expected.to redirect_to(budget_transactions_path(budget)) }

      it "initializes the form with transaction parameters" do
        expect(TransactionForm).to have_received(:new).with(
          account:     account,
          amount:      "100",
          budget:      budget,
          date:        "2026-03-18",
          memo:        "A memo",
          payee:       "Test Payee",
          subcategory: subcategory
        )
      end

      it "updates the form" do
        expect(form).to have_received(:update).with(transaction)
      end
    end

    context "when invalid" do
      let(:form) { instance_double(TransactionForm, update: false) }

      before do
        patch :update, params: {
          budget_id:        budget.id,
          id:               transaction.id,
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

      it { is_expected.to respond_with(422) }
      it { is_expected.to render_template(:edit) }

      it "initializes the form" do
        expect(TransactionForm).to have_received(:new).with(
          account:     account,
          amount:      "invalid",
          budget:      budget,
          date:        "2026-03-18",
          memo:        "A memo",
          payee:       "Test Payee",
          subcategory: subcategory
        )
      end

      it "assigns the budget accounts" do
        expect(assigns(:accounts)).to eq(budget.accounts)
      end

      it "assigns non-inflow categories sorted by position" do
        expect(assigns(:categories)).to eq(budget.categories.reject(&:inflow?).sort_by(&:position))
      end

      it "assigns the transaction" do
        expect(assigns(:transaction)).to eq(transaction)
      end

      it "assigns a transaction form" do
        expect(assigns(:form)).to eq(form)
      end
    end

    context "with a stored return location" do
      let(:form) { instance_double(TransactionForm, update: true) }

      before do
        session[:return_to] = "/stored-location"

        patch :update, params: {
          budget_id:        budget.id,
          id:               transaction.id,
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

      it { is_expected.to redirect_to("/stored-location") }

      it "clears the stored return location" do
        expect(session[:return_to]).to be_nil
      end
    end
  end
end
