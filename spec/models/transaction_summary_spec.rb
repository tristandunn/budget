# frozen_string_literal: true

require "rails_helper"

describe TransactionSummary do
  subject(:summary) { described_class.new(budget, ids: [outflow.id, inflow.id]) }

  let(:budget)  { create(:budget) }
  let(:inflow)  { create(:transaction, budget: budget, amount: 2_500) }
  let(:outflow) { create(:transaction, budget: budget, amount: -1_000) }

  describe "#size" do
    it "returns the number of selected transactions" do
      expect(summary.size).to eq(2)
    end
  end

  describe "#total" do
    it "returns the summed amount of the selection" do
      expect(summary.total).to eq(1_500)
    end

    context "when a selected transaction belongs to another budget" do
      let(:inflow) { create(:transaction, amount: 2_500) }

      it "excludes it from the total" do
        expect(summary.total).to eq(-1_000)
      end
    end
  end

  describe "#transactions" do
    it "returns the selected transactions" do
      expect(summary.transactions).to contain_exactly(outflow, inflow)
    end

    context "when a selected transaction belongs to another budget" do
      let(:inflow) { create(:transaction, amount: 2_500) }

      it "excludes it from the selection" do
        expect(summary.transactions).to contain_exactly(outflow)
      end
    end
  end
end
