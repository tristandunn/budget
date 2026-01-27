# frozen_string_literal: true

require "rails_helper"

describe TransactionForm, type: :form do
  it { is_expected.to be_a(BaseForm) }

  describe "#amount" do
    subject { form.amount }

    let(:form) { described_class.new(amount: amount) }

    context "when amount is zero" do
      let(:amount) { "0" }

      it { is_expected.to be_nil }
    end

    context "when amount is present" do
      let(:amount) { "10.50" }

      it { is_expected.to eq(Money.from_amount(10.50)) }
    end
  end

  describe "#save" do
    subject(:save) { form.save }

    let(:budget)      { subcategory.budget }
    let(:form)        { described_class.new(amount: amount, budget: budget, subcategory: subcategory) }
    let(:subcategory) { create(:category, :subcategory) }

    before do
      allow(CreateTransaction).to receive(:call).and_return(result)
    end

    context "when valid" do
      let(:amount) { "25.00" }
      let(:result) { true }

      it { is_expected.to be(true) }

      it "creates a transaction" do
        save

        expect(CreateTransaction).to have_received(:call).with(transaction: form.transaction)
      end
    end

    context "when invalid" do
      let(:amount) { "0" }
      let(:result) { false }

      it { is_expected.to be_nil }

      it "does not create a transaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end
    end
  end

  describe "#transaction" do
    subject(:transaction) { form.transaction }

    let(:budget)      { subcategory.budget }
    let(:form)        { described_class.new(amount: "15.00", budget: budget, subcategory: subcategory) }
    let(:subcategory) { create(:category, :subcategory) }

    it { is_expected.to be_a(Transaction) }

    it "sets the amount in cents" do
      expect(transaction.amount).to eq(1500)
    end

    it "sets the budget" do
      expect(transaction.budget).to eq(budget)
    end

    it "sets the subcategory" do
      expect(transaction.subcategory).to eq(subcategory)
    end
  end
end
