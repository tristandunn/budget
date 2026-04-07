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
        account:     transaction.account,
        amount:      -1500,
        budget:      transaction.budget,
        date:        transaction.date.advance(months: 1),
        frequency:   "monthly",
        memo:        transaction.memo,
        payee:       transaction.payee,
        subcategory: transaction.subcategory
      )
    end

    it "clears the frequency on the original transaction" do
      expect(transaction.frequency).to be_nil
    end

    it "calls CreateTransaction" do
      expect(CreateTransaction).to have_received(:call).with(transaction: transaction)
    end
  end
end
