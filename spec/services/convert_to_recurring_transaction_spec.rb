# frozen_string_literal: true

require "rails_helper"

describe ConvertToRecurringTransaction do
  describe ".call" do
    let(:frequency)       { "monthly" }
    let(:new_date)        { Date.current.advance(days: -3) }
    let(:next_occurrence) { Transaction.where.not(id: transaction.id).last }
    let(:transaction)     { create(:transaction, amount: -1500, memo: "Rent") }

    let(:new_attributes) do
      {
        account:     transaction.account,
        amount:      -2000,
        date:        new_date,
        frequency:   frequency,
        memo:        "Updated rent",
        payee:       create(:payee, budget: transaction.budget),
        subcategory: transaction.subcategory
      }
    end

    before do
      allow(UpdateTransaction).to receive(:call).and_call_original

      described_class.call(attributes: new_attributes, transaction: transaction)
    end

    it "creates the next occurrence from the updated transaction" do
      expect(next_occurrence).to have_attributes(
        amount:    -2000,
        date:      new_date.advance(months: 1),
        frequency: "monthly",
        memo:      "Updated rent",
        status:    "upcoming"
      )
    end

    it "copies the transaction associations to the next occurrence" do
      expect(next_occurrence).to have_attributes(
        account:     transaction.account,
        budget:      transaction.budget,
        payee:       transaction.payee,
        subcategory: transaction.subcategory
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
          date:      new_date.advance(weeks: 1),
          frequency: "weekly"
        )
      end
    end
  end
end
