# frozen_string_literal: true

require "rails_helper"

describe Transactions::SummariesController do
  let(:budget)       { create(:budget) }
  let(:summary)      { instance_double(TransactionSummary) }
  let(:transactions) { create_list(:transaction, 2, budget: budget) }

  before do
    sign_in_for(budget)
  end

  it { is_expected.to be_a(ApplicationController) }

  describe "#show" do
    before do
      allow(TransactionSummary).to receive(:new).and_return(summary)

      get :show, params: { budget_id: budget.id, ids: transactions.map(&:id) }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:show) }

    it "initializes the summary with the selected ids" do
      expect(TransactionSummary).to have_received(:new).with(
        budget,
        ids: transactions.map { |transaction| transaction.id.to_s }
      )
    end

    it "assigns the summary" do
      expect(assigns(:summary)).to eq(summary)
    end
  end
end
