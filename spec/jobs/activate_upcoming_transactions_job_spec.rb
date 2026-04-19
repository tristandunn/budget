# frozen_string_literal: true

require "rails_helper"

describe ActivateUpcomingTransactionsJob do
  subject(:klass) { described_class }

  it "inherits from ApplicationJob" do
    expect(klass.superclass).to eq(ApplicationJob)
  end

  describe "#perform" do
    before do
      allow(ActivateTransaction).to receive(:call)
      allow(PostRecurringTransaction).to receive(:call)
    end

    it "calls ActivateTransaction for each non-recurring due transaction" do
      transaction = create(:transaction, :upcoming, date: Date.current)

      described_class.new.perform

      expect(ActivateTransaction).to have_received(:call).with(transaction: transaction)
    end

    it "calls PostRecurringTransaction for each recurring due transaction" do
      transaction = create(:transaction, :recurring, date: Date.current)

      described_class.new.perform

      expect(PostRecurringTransaction).to have_received(:call).with(transaction: transaction)
    end

    it "does not activate upcoming transactions with a future date" do
      create(:transaction, :upcoming)

      described_class.new.perform

      expect(ActivateTransaction).not_to have_received(:call)
    end

    it "does not activate pending transactions" do
      create(:transaction, date: Date.current)

      described_class.new.perform

      expect(ActivateTransaction).not_to have_received(:call)
    end

    context "when budgets are on different calendar dates" do
      before do
        travel_to(Time.utc(2026, 4, 19, 3))
      end

      it "skips a transaction whose date is still future in the budget's zone" do
        budget    = create(:budget, settings: { time_zone: "Hawaii" })
        recurring = create(:transaction, :recurring, budget: budget, date: Date.new(2026, 4, 19))

        described_class.new.perform

        expect(PostRecurringTransaction).not_to have_received(:call).with(transaction: recurring)
      end

      it "posts a transaction whose date is today in the budget's zone" do
        budget    = create(:budget, settings: { time_zone: "Asia/Tokyo" })
        recurring = create(:transaction, :recurring, budget: budget, date: Date.new(2026, 4, 19))

        described_class.new.perform

        expect(PostRecurringTransaction).to have_received(:call).with(transaction: recurring)
      end
    end
  end
end
