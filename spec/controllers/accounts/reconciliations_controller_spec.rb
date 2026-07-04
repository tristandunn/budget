# frozen_string_literal: true

require "rails_helper"

describe Accounts::ReconciliationsController do
  let(:account) { create(:account, budget: budget) }
  let(:budget)  { create(:budget) }

  before do
    sign_in_for(budget)
  end

  describe "#create" do
    before do
      create(:transaction, :cleared, account: account)

      post :create, params: { budget_id: budget.id, account_id: account.id }
    end

    it { is_expected.to redirect_to(budget_account_transactions_path(budget, account)) }
    it { is_expected.to respond_with(:see_other) }

    it "marks cleared transactions as reconciled" do
      expect(account.transactions.reconciled.count).to eq(1)
    end
  end
end
