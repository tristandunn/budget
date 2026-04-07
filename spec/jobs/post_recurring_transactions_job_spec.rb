# frozen_string_literal: true

require "rails_helper"

describe PostRecurringTransactionsJob do
  subject(:klass) { described_class }

  it "inherits from ApplicationJob" do
    expect(klass.superclass).to eq(ApplicationJob)
  end

  describe "#perform" do
    before do
      allow(PostRecurringTransaction).to receive(:call)
    end

    it "calls PostRecurringTransaction for each recurring due transaction" do
      transaction = create(:transaction, :recurring, date: Date.current)

      described_class.new.perform

      expect(PostRecurringTransaction).to have_received(:call).with(transaction: transaction)
    end

    it "does not call PostRecurringTransaction when no transactions are due" do
      create(:transaction, :recurring, date: 1.day.from_now)

      described_class.new.perform

      expect(PostRecurringTransaction).not_to have_received(:call)
    end
  end
end
