# frozen_string_literal: true

require "rails_helper"

describe AccountsController do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
  end

  describe "#index" do
    context "with a budget" do
      let(:budget)         { cash_account.budget }
      let(:cash_account)   { create(:account, budget: credit_account.budget) }
      let(:credit_account) { create(:account, :credit) }

      before do
        get :index, params: { budget_id: budget.id }
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:index) }

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the cash accounts" do
        expect(assigns(:cash_accounts)).to contain_exactly(cash_account)
      end

      it "assigns the credit accounts" do
        expect(assigns(:credit_accounts)).to contain_exactly(credit_account)
      end
    end
  end

  describe "#new" do
    let(:budget) { create(:budget) }

    before do
      get :new, params: { budget_id: budget.id }
    end

    it { is_expected.to render_template(:new) }
    it { is_expected.to respond_with(200) }

    it "assigns the budget" do
      expect(assigns(:budget)).to eq(budget)
    end

    it "assigns a new form" do
      expect(assigns(:form)).to be_a(AccountForm).and(have_attributes(budget: budget))
    end
  end

  describe "#create" do
    let(:budget) { create(:budget) }

    context "with valid parameters" do
      before do
        post :create, params: { budget_id:    budget.id,
                                account_form: { name: "Checking", credit: "false" } }
      end

      it { is_expected.to redirect_to(budget_accounts_path(budget)) }
      it { is_expected.to respond_with(:see_other) }

      it "creates the account" do
        expect(budget.accounts.find_by(name: "Checking", credit: false)).to be_present
      end
    end

    context "with invalid parameters" do
      before do
        post :create, params: { budget_id:    budget.id,
                                account_form: { name: "", credit: "false" } }
      end

      it { is_expected.to render_template(:new) }
      it { is_expected.to respond_with(:unprocessable_content) }

      it "does not create an account" do
        expect(budget.accounts).to be_empty
      end
    end
  end

  describe "#edit" do
    let(:account)   { create(:account) }
    let(:budget)    { account.budget }

    before do
      get :edit, params: { budget_id: budget.id, id: account.id }
    end

    it { is_expected.to render_template(:edit) }
    it { is_expected.to respond_with(200) }

    it "assigns the budget" do
      expect(assigns(:budget)).to eq(budget)
    end

    it "assigns the form" do
      expect(assigns(:form)).to be_a(AccountForm).and(have_attributes(account: account))
    end

    context "with an account belonging to a different budget" do
      let(:other_account) { create(:account) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :edit, params: { budget_id: budget.id, id: other_account.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#update" do
    let(:account) { create(:account) }
    let(:budget)  { account.budget }

    context "with valid parameters" do
      before do
        patch :update, params: { budget_id:    budget.id,
                                 id:           account.id,
                                 account_form: { name: "Renamed", credit: "true" } }
      end

      it { is_expected.to redirect_to(budget_account_transactions_path(budget, account)) }
      it { is_expected.to respond_with(:see_other) }

      it "updates the account" do
        expect(account.reload).to have_attributes(name: "Renamed", credit: true)
      end
    end

    context "with invalid parameters" do
      before do
        patch :update, params: { budget_id:    budget.id,
                                 id:           account.id,
                                 account_form: { name: "", credit: "false" } }
      end

      it { is_expected.to render_template(:edit) }
      it { is_expected.to respond_with(:unprocessable_content) }

      it "does not update the account" do
        original_name = account.name

        expect(account.reload.name).to eq(original_name)
      end
    end

    context "when the account has transactions" do
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        create(:transaction, account: account, budget: budget, subcategory: subcategory)

        patch :update, params: { budget_id:    budget.id,
                                 id:           account.id,
                                 account_form: { name: "Renamed", credit: "true" } }
      end

      it "updates the name" do
        expect(account.reload.name).to eq("Renamed")
      end

      it "ignores the submitted credit value" do
        expect(account.reload.credit).to be(false)
      end
    end

    context "with an account belonging to a different budget" do
      let(:other_account) { create(:account) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect do
          patch :update, params: { budget_id:    budget.id,
                                   id:           other_account.id,
                                   account_form: { name: "Renamed", credit: "false" } }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#destroy" do
    let(:account) { create(:account) }
    let(:budget)  { account.budget }

    context "without transactions" do
      before do
        delete :destroy, params: { budget_id: budget.id, id: account.id }
      end

      it { is_expected.to redirect_to(budget_accounts_path(budget)) }
      it { is_expected.to respond_with(:see_other) }

      it "destroys the account" do
        expect(Account.exists?(account.id)).to be(false)
      end
    end

    context "with transactions" do
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        create(:transaction, account: account, budget: budget, subcategory: subcategory)

        delete :destroy, params: { budget_id: budget.id, id: account.id }
      end

      it { is_expected.to redirect_to(budget_account_transactions_path(budget, account)) }
      it { is_expected.to respond_with(:see_other) }

      it "does not destroy the account" do
        expect(Account.exists?(account.id)).to be(true)
      end
    end

    context "with an account belonging to a different budget" do
      let(:other_account) { create(:account) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { delete :destroy, params: { budget_id: budget.id, id: other_account.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
