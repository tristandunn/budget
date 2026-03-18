# frozen_string_literal: true

require "rails_helper"

describe TransactionForm, type: :form do
  it { is_expected.to be_a(BaseForm) }

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

    let(:account)       { create(:account, budget: subcategory.budget) }
    let(:subcategory)   { create(:category, :subcategory) }

    context "when valid" do
      let(:form) do
        described_class.new(
          account:     account,
          amount:      "25.00",
          budget:      subcategory.budget,
          date:        "2026-03-18",
          memo:        "A memo",
          payee:       "Test Payee",
          subcategory: subcategory
        )
      end

      before do
        allow(CreateTransaction).to receive(:call).and_return(true)
      end

      it { is_expected.to be(true) }

      it "creates a transaction" do
        save

        expect(CreateTransaction).to have_received(:call).with(transaction: form.transaction)
      end
    end

    context "when valid with negative amount" do
      let(:form) do
        described_class.new(
          account:     account,
          amount:      "-25.00",
          budget:      subcategory.budget,
          date:        "2026-03-18",
          payee:       "Test Payee",
          subcategory: subcategory
        )
      end

      before do
        allow(CreateTransaction).to receive(:call).and_return(true)
      end

      it { is_expected.to be(true) }

      it "creates a transaction" do
        save

        expect(CreateTransaction).to have_received(:call).with(transaction: form.transaction)
      end
    end

    context "when invalid" do
      let(:form) do
        described_class.new(
          account:     account,
          amount:      "0",
          budget:      subcategory.budget,
          date:        "2026-03-18",
          payee:       "Test Payee",
          subcategory: subcategory
        )
      end

      before do
        allow(CreateTransaction).to receive(:call)
      end

      it { is_expected.to be_nil }

      it "does not create a transaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end
    end
  end

  describe "#transaction" do
    subject(:transaction) { form.transaction }

    let(:account)     { create(:account, budget: budget) }
    let(:budget)      { subcategory.budget }
    let(:subcategory) { create(:category, :subcategory) }

    let(:form) do
      described_class.new(
        account:     account,
        amount:      "15.00",
        budget:      budget,
        date:        "2026-03-18",
        memo:        "Lunch",
        payee:       "Test Payee",
        subcategory: subcategory
      )
    end

    it { is_expected.to be_a(Transaction) }

    it "sets the account" do
      expect(transaction.account).to eq(account)
    end

    it "sets the amount in cents" do
      expect(transaction.amount).to eq(1500)
    end

    it "sets the budget" do
      expect(transaction.budget).to eq(budget)
    end

    it "sets the date" do
      expect(transaction.date).to eq(Date.new(2026, 3, 18))
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

    context "with negative amount" do
      let(:form) do
        described_class.new(
          account:     account,
          amount:      "-15.00",
          budget:      budget,
          date:        "2026-03-18",
          payee:       "Test Payee",
          subcategory: subcategory
        )
      end

      it "sets the amount as negative cents" do
        expect(transaction.amount).to eq(-1500)
      end
    end
  end
end
