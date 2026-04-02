# frozen_string_literal: true

require "rails_helper"

describe TransactionsController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#index" do
    let(:budget) { create(:budget) }

    context "with transactions" do
      let!(:newer) { create(:transaction, budget: budget, date: Date.new(2026, 3, 15)) }
      let!(:older) { create(:transaction, budget: budget, date: Date.new(2026, 3, 10)) }

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

    context "when hiding reconciled transactions" do
      let!(:transaction) { create(:transaction, budget: budget, date: Date.new(2026, 3, 15)) }

      before do
        create(:transaction, budget: budget, status: :reconciled, date: Date.new(2026, 3, 12))
        budget.settings.update(hide_reconciled: "1")

        get :index, params: { budget_id: budget.id }
      end

      it "excludes reconciled transactions" do
        expect(assigns(:grouped_transactions)).to eq(
          transaction.date => [transaction]
        )
      end
    end
  end

  describe "#new" do
    let(:account_id) { nil }
    let(:budget)     { create(:budget) }
    let(:form)       { instance_double(TransactionForm) }

    before do
      allow(TransactionForm).to receive(:new).and_return(form)

      request.headers["HTTP_REFERER"] = "/previous-page"

      get :new, params: { budget_id: budget.id, account_id: account_id }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:new) }

    it "initializes the form with the budget" do
      expect(TransactionForm).to have_received(:new).with(account: nil, budget: budget)
    end

    it "assigns the budget accounts" do
      expect(assigns(:accounts)).to eq(budget.accounts)
    end

    it "assigns categories sorted by position" do
      expect(assigns(:categories)).to eq(budget.categories.sort_by(&:position))
    end

    it "assigns a transaction form" do
      expect(assigns(:form)).to eq(form)
    end

    it "stores the referer in the session" do
      expect(session[:return_to]).to eq("/previous-page")
    end

    context "with an account" do
      let(:account)    { create(:account, budget: budget) }
      let(:account_id) { account.id }

      it "initializes the form with the account and budget" do
        expect(TransactionForm).to have_received(:new).with(account: account, budget: budget)
      end
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

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to(budget_transactions_path(budget)) }

      it "initializes the form with transaction parameters" do
        expect(TransactionForm).to have_received(:new).with(expected_parameters)
      end

      it "saves the form" do
        expect(form).to have_received(:save)
      end
    end

    context "with a stored return location" do
      let(:account)     { create(:account, budget: budget) }
      let(:budget)      { create(:budget) }
      let(:form)        { instance_double(TransactionForm, save: true) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        allow(TransactionForm).to receive(:new).and_return(form)

        session[:return_to] = "/stored-location"

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

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to("/stored-location") }

      it "clears the stored return location" do
        expect(session[:return_to]).to be_nil
      end
    end

    context "when invalid" do
      let(:budget)      { create(:budget) }
      let(:form)        { instance_double(TransactionForm, save: false) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      let(:expected_parameters) do
        {
          account:     nil,
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
            account_id:     "",
            amount:         "invalid",
            date:           "2026-03-18",
            memo:           "A memo",
            payee:          "Test Payee",
            subcategory_id: subcategory.id
          }
        }
      end

      it { is_expected.to respond_with(:unprocessable_content) }
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

      it "assigns categories sorted by position" do
        expect(assigns(:categories)).to eq(budget.categories.sort_by(&:position))
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

    it "assigns categories sorted by position" do
      expect(assigns(:categories)).to eq(budget.categories.sort_by(&:position))
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

    context "when the transaction is reconciled" do
      let(:transaction) { create(:transaction, :reconciled, budget: budget) }

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to("/previous-page") }
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

      it { is_expected.to respond_with(:see_other) }
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
            account_id:     "",
            amount:         "invalid",
            date:           "2026-03-18",
            memo:           "A memo",
            payee:          "Test Payee",
            subcategory_id: subcategory.id
          }
        }
      end

      it { is_expected.to respond_with(:unprocessable_content) }
      it { is_expected.to render_template(:edit) }

      it "initializes the form" do
        expect(TransactionForm).to have_received(:new).with(
          account:     nil,
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

      it "assigns categories sorted by position" do
        expect(assigns(:categories)).to eq(budget.categories.sort_by(&:position))
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

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to("/stored-location") }

      it "clears the stored return location" do
        expect(session[:return_to]).to be_nil
      end
    end

    context "when the transaction is reconciled" do
      let(:form)        { instance_double(TransactionForm) }
      let(:transaction) { create(:transaction, :reconciled, budget: budget) }

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

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to(budget_transactions_path(budget)) }

      it "does not update the transaction" do
        expect(transaction.reload.payee).not_to eq("Test Payee")
      end
    end
  end

  describe "#destroy" do
    let(:budget)      { create(:budget) }
    let(:transaction) { create(:transaction, budget: budget) }

    before do
      allow(DestroyTransaction).to receive(:call)

      delete :destroy, params: { budget_id: budget.id, id: transaction.id }
    end

    it { is_expected.to respond_with(:see_other) }
    it { is_expected.to redirect_to(budget_transactions_path(budget)) }

    it "calls the destroy service with the transaction" do
      expect(DestroyTransaction).to have_received(:call).with(transaction: transaction)
    end

    context "with a stored return location" do
      before do
        session[:return_to] = "/stored-location"

        delete :destroy, params: { budget_id: budget.id, id: transaction.id }
      end

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to("/stored-location") }

      it "clears the stored return location" do
        expect(session[:return_to]).to be_nil
      end
    end

    context "when the transaction is reconciled" do
      let(:transaction) { create(:transaction, :reconciled, budget: budget) }

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to(budget_transactions_path(budget)) }

      it "does not call the destroy service" do
        expect(DestroyTransaction).not_to have_received(:call).with(transaction: transaction)
      end

      it "does not destroy the transaction" do
        expect(Transaction.exists?(transaction.id)).to be(true)
      end
    end
  end

  describe "#clear" do
    let(:budget) { create(:budget) }

    context "when the transaction is pending" do
      let(:transaction) { create(:transaction, budget: budget) }

      before do
        patch :clear, params: { budget_id: budget.id, id: transaction.id }, format: :turbo_stream
      end

      it { is_expected.to respond_with(200) }

      it "changes the status to cleared" do
        expect(transaction.reload).to be_cleared
      end
    end

    context "when the transaction is reconciled" do
      let(:transaction) { create(:transaction, :reconciled, budget: budget) }

      before do
        patch :clear, params: { budget_id: budget.id, id: transaction.id }, format: :turbo_stream
      end

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to(budget_transactions_path(budget)) }

      it "does not change the status" do
        expect(transaction.reload).to be_reconciled
      end
    end
  end

  describe "#unclear" do
    let(:budget) { create(:budget) }

    context "when the transaction is cleared" do
      let(:transaction) { create(:transaction, :cleared, budget: budget) }

      before do
        delete :unclear, params: { budget_id: budget.id, id: transaction.id }, format: :turbo_stream
      end

      it { is_expected.to respond_with(200) }

      it "changes the status to pending" do
        expect(transaction.reload).to be_pending
      end
    end

    context "when the transaction is reconciled" do
      let(:transaction) { create(:transaction, :reconciled, budget: budget) }

      before do
        delete :unclear, params: { budget_id: budget.id, id: transaction.id }, format: :turbo_stream
      end

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to(budget_transactions_path(budget)) }

      it "does not change the status" do
        expect(transaction.reload).to be_reconciled
      end
    end
  end
end
