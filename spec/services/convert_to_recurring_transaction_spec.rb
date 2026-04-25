# frozen_string_literal: true

require "rails_helper"

describe ConvertToRecurringTransaction do
  describe ".call" do
    let(:frequency)       { "monthly" }
    let(:next_occurrence) { Transaction.where.not(id: transaction.id).last }
    let(:transaction)     { create(:transaction, amount: -1500, memo: "Rent") }

    def new_attributes
      {
        account:     transaction.account,
        amount:      transaction.amount,
        date:        transaction.date,
        frequency:   frequency,
        memo:        transaction.memo,
        payee:       transaction.payee,
        subcategory: transaction.subcategory
      }
    end

    before do
      allow(UpdateTransaction).to receive(:call).and_return(true)

      described_class.call(attributes: new_attributes, transaction: transaction)
    end

    it "creates the next occurrence with the correct attributes" do
      expect(next_occurrence).to have_attributes(
        **transaction.copyable_attributes,
        amount:    -1500,
        date:      transaction.date.advance(months: 1),
        frequency: "monthly",
        status:    "upcoming"
      )
    end

    it "calls UpdateTransaction with frequency set to nil" do
      expect(UpdateTransaction).to have_received(:call).with(
        attributes:  new_attributes.merge(frequency: nil),
        transaction: transaction
      )
    end

    context "with a custom frequency" do
      let(:frequency) { "weekly" }

      it "advances the next occurrence date by the custom frequency" do
        expect(next_occurrence).to have_attributes(
          date:      transaction.date.advance(weeks: 1),
          frequency: "weekly"
        )
      end
    end
  end
end
