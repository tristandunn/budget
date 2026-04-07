# frozen_string_literal: true

require "rails_helper"

describe TransactionForm, type: :form do
  it { is_expected.to be_a(BaseForm) }

  describe ".from" do
    subject(:form) { described_class.from(transaction: transaction) }

    let(:transaction) { create(:transaction, amount: -1500, frequency: :monthly, memo: "Lunch") }

    it "sets the account" do
      expect(form.account).to eq(transaction.account)
    end

    it "sets the amount as a decimal string" do
      expect(form.amount).to eq(Money.from_amount(BigDecimal("-15.00")))
    end

    it "sets the budget" do
      expect(form.budget).to eq(transaction.budget)
    end

    it "sets the date" do
      expect(form.date).to eq(transaction.date)
    end

    it "sets the frequency" do
      expect(form.frequency).to eq("monthly")
    end

    it "sets the memo" do
      expect(form.memo).to eq("Lunch")
    end

    it "sets the payee" do
      expect(form.payee).to eq(transaction.payee)
    end

    it "sets the subcategory" do
      expect(form.subcategory).to eq(transaction.subcategory)
    end
  end

  describe "#amount" do
    subject { form.amount }

    let(:form) { described_class.new(amount: amount) }

    context "when amount is blank" do
      let(:amount) { "" }

      it { is_expected.to be_nil }
    end

    context "when amount is nil" do
      let(:amount) { nil }

      it { is_expected.to be_nil }
    end

    context "when amount is zero" do
      let(:amount) { "0" }

      it { is_expected.to be_nil }
    end

    context "when amount is positive" do
      let(:amount) { "10.50" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("10.50"))) }
    end

    context "when amount is negative" do
      let(:amount) { "-10.50" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("-10.50"))) }
    end
  end

  describe "#date" do
    subject { form.date }

    let(:form) { described_class.new(date: date) }

    context "when date is a valid string" do
      let(:date) { "2026-03-18" }

      it { is_expected.to eq(Date.new(2026, 3, 18)) }
    end

    context "when date is blank" do
      let(:date) { "" }

      it { is_expected.to eq(Date.current) }
    end

    context "when date is nil" do
      let(:date) { nil }

      it { is_expected.to eq(Date.current) }
    end

    context "when date is invalid" do
      let(:date) { "not-a-date" }

      it { is_expected.to eq(Date.current) }
    end
  end

  describe "#save" do
    subject(:save) { form.save }

    let(:account)     { create(:account, budget: subcategory.budget) }
    let(:subcategory) { create(:category, :subcategory) }

    let(:attributes) do
      {
        account:     account,
        amount:      "25.00",
        budget:      subcategory.budget,
        date:        "2026-03-18",
        memo:        "A memo",
        payee:       "Test Payee",
        subcategory: subcategory
      }
    end

    let(:form) { described_class.new(**attributes) }

    before do
      allow(CreateTransaction).to receive(:call).and_return(true)
      allow(PostRecurringTransaction).to receive(:call).and_return(true)
    end

    context "when valid" do
      it { is_expected.to be(true) }

      it "creates a transaction" do
        save

        expect(CreateTransaction).to have_received(:call).with(transaction: form.transaction)
      end

      it "does not call PostRecurringTransaction" do
        save

        expect(PostRecurringTransaction).not_to have_received(:call)
      end
    end

    context "when valid with negative amount" do
      let(:form) { described_class.new(**attributes, amount: "-25.00") }

      it { is_expected.to be(true) }

      it "creates a transaction" do
        save

        expect(CreateTransaction).to have_received(:call).with(transaction: form.transaction)
      end
    end

    context "when invalid" do
      let(:form) { described_class.new(**attributes, amount: "0") }

      it { is_expected.to be_nil }

      it "does not create a transaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end
    end

    context "when recurring and scheduled" do
      let(:form) do
        described_class.new(**attributes, date: 1.month.from_now.to_date.to_s, frequency: "monthly")
      end

      it { is_expected.to be(true) }

      it "saves the transaction directly" do
        save

        expect(form.transaction).to be_persisted
      end

      it "does not call CreateTransaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end

      it "does not call PostRecurringTransaction" do
        save

        expect(PostRecurringTransaction).not_to have_received(:call)
      end
    end

    context "when recurring but not scheduled" do
      let(:form) do
        described_class.new(**attributes, date: Date.current.to_s, frequency: "monthly")
      end

      it { is_expected.to be(true) }

      it "calls PostRecurringTransaction" do
        save

        expect(PostRecurringTransaction).to have_received(:call).with(transaction: form.transaction)
      end

      it "does not call CreateTransaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end
    end
  end

  describe "#transaction" do
    subject(:transaction) { form.transaction }

    let(:account)     { create(:account, budget: subcategory.budget) }
    let(:subcategory) { create(:category, :subcategory) }

    let(:attributes) do
      {
        account:     account,
        amount:      "15.00",
        budget:      subcategory.budget,
        date:        "2026-03-18",
        memo:        "Lunch",
        payee:       "Test Payee",
        subcategory: subcategory
      }
    end

    let(:form) { described_class.new(**attributes) }

    it { is_expected.to be_a(Transaction) }

    it "sets the account" do
      expect(transaction.account).to eq(account)
    end

    it "sets the amount in cents" do
      expect(transaction.amount).to eq(1500)
    end

    it "sets the budget" do
      expect(transaction.budget).to eq(subcategory.budget)
    end

    it "sets the date" do
      expect(transaction.date).to eq(Date.new(2026, 3, 18))
    end

    it "sets the frequency" do
      expect(transaction.frequency).to be_nil
    end

    it "sets the memo" do
      expect(transaction.memo).to eq("Lunch")
    end

    it "sets the payee" do
      expect(transaction.payee).to eq("Test Payee")
    end

    it "sets the subcategory" do
      expect(transaction.subcategory).to eq(subcategory)
    end

    context "with frequency" do
      let(:form) { described_class.new(**attributes, frequency: "monthly") }

      it "sets the frequency" do
        expect(transaction.frequency).to eq("monthly")
      end
    end

    context "with blank frequency" do
      let(:form) { described_class.new(**attributes, frequency: "") }

      it "sets the frequency to nil" do
        expect(transaction.frequency).to be_nil
      end
    end

    context "with negative amount" do
      let(:form) { described_class.new(**attributes, amount: "-15.00") }

      it "sets the amount as negative cents" do
        expect(transaction.amount).to eq(-1500)
      end
    end
  end

  describe "#update" do
    subject(:update) { form.update(transaction) }

    let(:attributes) do
      {
        account:     transaction.account,
        amount:      "25.00",
        budget:      transaction.budget,
        date:        "2026-03-18",
        memo:        "A memo",
        payee:       "Test Payee",
        subcategory: transaction.subcategory
      }
    end

    let(:form)        { described_class.new(**attributes) }
    let(:transaction) { create(:transaction) }

    before do
      allow(ActivateTransaction).to receive(:call).and_return(true)
      allow(ConvertToRecurringTransaction).to receive(:call).and_return(true)
      allow(DirectUpdateTransaction).to receive(:call).and_return(true)
      allow(SuspendTransaction).to receive(:call).and_return(true)
      allow(UpdateTransaction).to receive(:call).and_return(true)
    end

    context "when valid" do
      it { is_expected.to be(true) }

      it "calls UpdateTransaction" do
        update

        expect(UpdateTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget).merge(amount: 2500, date: Date.new(2026, 3, 18), frequency: nil),
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end
    end

    context "when invalid" do
      let(:form) { described_class.new(**attributes, amount: "0") }

      it { is_expected.to be_nil }

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end
    end

    context "when becoming recurring" do
      let(:form) do
        described_class.new(**attributes, date: 1.month.from_now.to_date.to_s, frequency: "monthly")
      end

      it { is_expected.to be(true) }

      it "calls SuspendTransaction" do
        update

        expect(SuspendTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget).merge(
            amount:    2500,
            date:      1.month.from_now.to_date,
            frequency: "monthly"
          ),
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when becoming recurring now" do
      let(:form) do
        described_class.new(**attributes, date: Date.current.to_s, frequency: "monthly")
      end

      it { is_expected.to be(true) }

      it "calls ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget).merge(
            amount:    2500,
            date:      Date.current,
            frequency: "monthly"
          ),
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when activating" do
      let(:form)        { described_class.new(**attributes) }
      let(:transaction) { create(:transaction, :recurring) }

      it { is_expected.to be(true) }

      it "calls ActivateTransaction" do
        update

        expect(ActivateTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget).merge(
            amount:    2500,
            date:      Date.new(2026, 3, 18),
            frequency: nil
          ),
          transaction: transaction
        )
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when recurring and scheduled" do
      let(:form) do
        described_class.new(**attributes, date: 1.month.from_now.to_date.to_s, frequency: "monthly")
      end

      let(:transaction) { create(:transaction, :recurring) }

      it { is_expected.to be(true) }

      it "calls DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget).merge(
            amount:    2500,
            date:      1.month.from_now.to_date,
            frequency: "monthly"
          ),
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end
    end

    context "when recurring but not scheduled" do
      let(:form) do
        described_class.new(**attributes, date: Date.current.to_s, frequency: "monthly")
      end

      let(:transaction) { create(:transaction, :recurring, date: Date.current) }

      it { is_expected.to be(true) }

      it "calls ActivateTransaction" do
        update

        expect(ActivateTransaction).to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end
  end
end
