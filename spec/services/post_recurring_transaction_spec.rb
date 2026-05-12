# frozen_string_literal: true

require "rails_helper"

describe PostRecurringTransaction do
  describe ".call" do
    let(:next_occurrence) { Transaction.where.not(id: transaction.id).last }
    let(:transaction)     { create(:transaction, amount: -1500, frequency: :monthly, memo: "Rent") }

    before do
      allow(CreateTransaction).to receive(:call).and_return(true)

      described_class.call(transaction: transaction)
    end

    it "creates the next occurrence with the same attributes and an advanced date" do
      expect(next_occurrence).to have_attributes(
        **transaction.copyable_attributes,
        amount:    -1500,
        date:      transaction.date.advance(months: 1),
        frequency: "monthly",
        status:    "upcoming"
      )
    end

    it "clears the frequency and sets the status to pending on the original" do
      expect(transaction).to have_attributes(frequency: nil, status: "pending")
    end

    it "calls CreateTransaction" do
      expect(CreateTransaction).to have_received(:call).with(transaction: transaction)
    end

    context "with an unpersisted transaction and a new payee" do
      let(:account)     { create(:account) }
      let(:payee)       { Payee.new(budget: account.budget, name: "New Payee") }
      let(:transaction) do
        Transaction.new(
          account:     account,
          amount:      -1500,
          budget:      account.budget,
          date:        Date.current,
          frequency:   :monthly,
          payee:       payee,
          subcategory: create(:category, :subcategory, budget: account.budget)
        )
      end

      it "creates the next occurrence with the new payee" do
        expect(next_occurrence.payee).to eq(payee)
      end
    end
  end
end
