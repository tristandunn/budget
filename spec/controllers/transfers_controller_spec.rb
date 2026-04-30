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
  end

  describe "#create" do
    let(:budget) { create(:budget) }

    context "when valid" do
      let(:from_account) { create(:account, budget: budget, name: "Checking") }
      let(:to_account)   { create(:account, budget: budget, name: "Savings") }

      before do
        allow(CreateTransfer).to receive(:call)

        post :create, params: {
          budget_id: budget.id,
          transfer:  {
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

      it "calls the transfer service with the expected parameters" do
        expect(CreateTransfer).to have_received(:call).with(
          accounts: { from: from_account, to: to_account },
          amount:   Money.from_amount(BigDecimal("50.00")),
          budget:   budget,
          date:     "2026-04-15",
          memo:     "Move savings"
        )
      end
    end

    context "when memo is blank" do
      let(:from_account) { create(:account, budget: budget) }
      let(:to_account)   { create(:account, budget: budget) }

      before do
        allow(CreateTransfer).to receive(:call)

        post :create, params: {
          budget_id: budget.id,
          transfer:  {
            amount:          "50.00",
            date:            "2026-04-15",
            from_account_id: from_account.id,
            memo:            "",
            to_account_id:   to_account.id
          }
        }
      end

      it "passes nil as the memo" do
        expect(CreateTransfer).to have_received(:call).with(hash_including(memo: nil))
      end
    end

    context "with a non-existent from_account_id" do
      let(:to_account) { create(:account, budget: budget) }
      let(:transfer)   do
        { amount: "50.00", date: "2026-04-15", from_account_id: 0, memo: "", to_account_id: to_account.id }
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { post :create, params: { budget_id: budget.id, transfer: transfer } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
