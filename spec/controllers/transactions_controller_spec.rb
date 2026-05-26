# frozen_string_literal: true

require "rails_helper"

describe TransactionsController do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
  end

  it { is_expected.to be_a(ApplicationController) }

  describe "#index" do
    context "with transactions" do
      let!(:newer)    { create(:transaction, budget: budget, date: 5.days.ago.to_date) }
      let!(:older)    { create(:transaction, budget: budget, date: 10.days.ago.to_date) }
      let!(:upcoming) { create(:transaction, :upcoming, budget: budget) }

      before do
        create(:transaction)
        create(:transaction, budget: budget, date: 32.days.ago.to_date)

        get :index, params: { budget_id: budget.id }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:index) }

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the current transactions limited to the previous 31 days" do
        expect(assigns(:current_transactions)).to eq([newer, older])
      end

      it "assigns the scheduled transactions" do
        expect(assigns(:scheduled_transactions)).to eq([upcoming])
      end
    end

    context "when hiding reconciled transactions" do
      let!(:transaction) { create(:transaction, budget: budget, date: 5.days.ago.to_date) }

      before do
        create(:transaction, budget: budget, status: :reconciled, date: 10.days.ago.to_date)
        budget.settings.update(hide_reconciled: "1")

        get :index, params: { budget_id: budget.id }
      end

      it "excludes reconciled transactions" do
        expect(assigns(:current_transactions)).to eq([transaction])
      end
    end
  end

  describe "#new" do
    let(:account_id) { nil }
    let(:form)       { instance_double(TransactionForm, budget: budget, subcategory: nil) }

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

    it "assigns a transaction form" do
      expect(assigns(:form)).to eq(form)
    end

    it "stores the referer in the session" do
      expect(session[:return_to]).to eq("/previous-page")
    end

    it "assigns the payees" do
      expect(assigns(:payees)).to be_empty
    end

    it "assigns the accounts" do
      expect(assigns(:accounts)).to be_empty
    end

    it "assigns the category picker" do
      expect(assigns(:category_picker)).to be_a(Transactions::CategoryPicker)
    end

    context "with an account" do
      let(:account)    { create(:account, budget: budget) }
      let(:account_id) { account.id }

      it "initializes the form with the account and budget" do
        expect(TransactionForm).to have_received(:new).with(account: account, budget: budget)
      end
    end

    context "with accounts" do
      let(:cash_account) { create(:account, budget: budget, name: "Checking") }
      let(:credit_card)  { create(:account, :credit, budget: budget, name: "Visa") }

      before do
        credit_card

        get :new, params: { budget_id: cash_account.budget_id }
      end

      it "assigns the accounts" do
        expect(assigns(:accounts)).to eq([cash_account, credit_card])
      end
    end

    context "with payees" do
      let(:payee) { create(:payee, budget: budget, name: "Alpha") }

      before do
        get :new, params: { budget_id: payee.budget_id }
      end

      it "assigns the payees" do
        expect(assigns(:payees)).to eq([payee])
      end
    end
  end

  describe "#create" do
    context "when valid" do
      let(:account)     { create(:account, budget: budget) }
      let(:form)        { instance_double(TransactionForm, save: true) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      let(:expected_parameters) do
        {
          account:     account,
          amount:      "100",
          budget:      budget,
          date:        "2026-03-18",
          frequency:   "monthly",
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
            frequency:      "monthly",
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
            frequency:      "monthly",
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
      let(:form)        { instance_double(TransactionForm, budget: budget, save: false, subcategory: nil) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      let(:expected_parameters) do
        {
          account:     nil,
          amount:      "invalid",
          budget:      budget,
          date:        "2026-03-18",
          frequency:   "",
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
            frequency:      "",
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

      it "assigns a transaction form" do
        expect(assigns(:form)).to eq(form)
      end

      it "assigns the payees" do
        expect(assigns(:payees)).to be_empty
      end

      it "assigns the accounts" do
        expect(assigns(:accounts)).to be_empty
      end

      it "assigns the category picker" do
        expect(assigns(:category_picker)).to be_a(Transactions::CategoryPicker)
      end
    end
  end

  describe "#edit" do
    let(:form)        { instance_double(TransactionForm, budget: budget, subcategory: nil) }
    let(:transaction) { create(:transaction, budget: budget) }

    before do
      allow(TransactionForm).to receive(:from).and_return(form)

      request.headers["HTTP_REFERER"] = "/previous-page"

      get :edit, params: { budget_id: budget.id, id: transaction.id }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:edit) }

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

    it "assigns the payees" do
      expect(assigns(:payees)).to eq([transaction.payee])
    end

    it "assigns the accounts" do
      expect(assigns(:accounts)).to eq([transaction.account])
    end

    it "assigns the category picker" do
      expect(assigns(:category_picker)).to be_a(Transactions::CategoryPicker)
    end

    context "when the transaction is reconciled" do
      let(:transaction) { create(:transaction, :reconciled, budget: budget) }

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to("/previous-page") }
    end

    context "when the transaction is a transfer" do
      let(:transaction) do
        create(:transaction,
               budget:        budget,
               transfer_pair: create(:transaction, budget: budget))
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:edit) }

      it "does not initialize a transaction form" do
        expect(TransactionForm).not_to have_received(:from)
      end

      it "does not assign a form" do
        expect(assigns(:form)).to be_nil
      end
    end
  end

  describe "#update" do
    let(:account)     { create(:account, budget: budget) }
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
            frequency:      "monthly",
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
          frequency:   "monthly",
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
      let(:form) { instance_double(TransactionForm, budget: budget, update: false, subcategory: nil) }

      before do
        patch :update, params: {
          budget_id:        budget.id,
          id:               transaction.id,
          transaction_form: {
            account_id:     "",
            amount:         "invalid",
            date:           "2026-03-18",
            frequency:      "",
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
          frequency:   "",
          memo:        "A memo",
          payee:       "Test Payee",
          subcategory: subcategory
        )
      end

      it "assigns the transaction" do
        expect(assigns(:transaction)).to eq(transaction)
      end

      it "assigns a transaction form" do
        expect(assigns(:form)).to eq(form)
      end

      it "assigns the payees" do
        expect(assigns(:payees)).to eq([transaction.payee])
      end

      it "assigns the accounts" do
        expect(assigns(:accounts)).to eq([transaction.account])
      end

      it "assigns the category picker" do
        expect(assigns(:category_picker)).to be_a(Transactions::CategoryPicker)
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
        expect(transaction.reload.payee.name).not_to eq("Test Payee")
      end
    end

    context "when the transaction is a transfer" do
      let(:form) { instance_double(TransactionForm) }

      let(:transaction) do
        create(:transaction,
               budget:        budget,
               transfer_pair: create(:transaction, budget: budget))
      end

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
        expect(transaction.reload.payee.name).not_to eq("Test Payee")
      end
    end
  end

  describe "#destroy" do
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

    context "when the transaction is a transfer with a reconciled partner" do
      let(:partner)     { create(:transaction, :reconciled, budget: budget) }
      let(:transaction) { create(:transaction, budget: budget, transfer_pair: partner) }

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to(budget_transactions_path(budget)) }

      it "does not call the destroy service" do
        expect(DestroyTransaction).not_to have_received(:call).with(transaction: transaction)
      end

      it "does not destroy the transaction" do
        expect(Transaction.exists?(transaction.id)).to be(true)
      end

      it "does not destroy the partner" do
        expect(Transaction.exists?(partner.id)).to be(true)
      end
    end
  end

  describe "#clear" do
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
