# frozen_string_literal: true

require "rails_helper"

describe Transaction do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    subject(:transaction) { build(:transaction) }

    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:budget) }
    it { is_expected.to belong_to(:payee) }

    it "belongs to a subcategory" do
      expect(transaction).to belong_to(:subcategory)
        .class_name("Category")
        .with_foreign_key(:category_id)
        .inverse_of(:transactions)
        .optional
    end

    it { is_expected.to belong_to(:transfer_pair).class_name("Transaction").optional }
  end

  describe "validations" do
    subject(:transaction) { create(:transaction) }

    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).only_integer }
    it { is_expected.to allow_value(1337).for(:amount) }
    it { is_expected.to allow_value(-723).for(:amount) }
    it { is_expected.not_to allow_value(0).for(:amount) }

    it { is_expected.to validate_presence_of(:date) }

    it "defines and validates a status enum" do
      expect(transaction).to define_enum_for(:status)
        .with_values(pending: 0, cleared: 1, reconciled: 2, upcoming: 3)
        .validating
    end

    it "defines a frequency enum" do
      expect(transaction).to define_enum_for(:frequency)
        .with_values(daily: 1, weekly: 7, every_other_week: 14, monthly: 30, yearly: 365)
        .validating(allowing_nil: true)
    end

    it "allows a nil frequency" do
      transaction.frequency = nil

      expect(transaction).to be_valid
    end
  end

  describe ".default_scope" do
    it "orders transactions by date ascending" do
      newer = create(:transaction, date: Date.new(2026, 3, 15))
      older = create(:transaction, date: Date.new(2026, 3, 10), budget: newer.budget)

      expect(described_class.all).to eq([older, newer])
    end

    it "orders transactions with the same date by created_at ascending" do
      first  = create(:transaction, date: Date.new(2026, 3, 15))
      second = create(:transaction, date: Date.new(2026, 3, 15), budget: first.budget)

      expect(described_class.all).to eq([first, second])
    end
  end

  describe ".activation_due" do
    it "includes upcoming transactions with today's date" do
      transaction = create(:transaction, :upcoming, date: Date.current)

      expect(described_class.activation_due).to include(transaction)
    end

    it "includes upcoming transactions with a past date" do
      transaction = create(:transaction, :upcoming, date: 1.day.ago.to_date)

      expect(described_class.activation_due).to include(transaction)
    end

    it "excludes upcoming transactions with a future date" do
      transaction = create(:transaction, :upcoming)

      expect(described_class.activation_due).not_to include(transaction)
    end

    it "excludes pending transactions with today's date" do
      transaction = create(:transaction, date: Date.current)

      expect(described_class.activation_due).not_to include(transaction)
    end
  end

  describe ".recent" do
    subject { described_class.recent }

    let(:transaction) { create(:transaction, date: date) }

    context "with today's date" do
      let(:date) { Date.current }

      it { is_expected.to include(transaction) }
    end

    context "with a date 30 days ago" do
      let(:date) { 30.days.ago.to_date }

      it { is_expected.to include(transaction) }
    end

    context "with a future date" do
      let(:date) { 1.week.from_now.to_date }

      it { is_expected.to include(transaction) }
    end

    context "with a date more than 30 days ago" do
      let(:date) { 31.days.ago.to_date }

      it { is_expected.not_to include(transaction) }
    end
  end

  describe "#copyable_attributes" do
    it "returns the attributes to copy when creating a new occurrence" do
      transaction = create(:transaction)

      expect(transaction.copyable_attributes).to eq(
        account_id:  transaction.account_id,
        amount:      transaction.amount,
        budget_id:   transaction.budget_id,
        category_id: transaction.category_id,
        memo:        transaction.memo,
        payee:       transaction.payee
      )
    end
  end

  describe "#clearable?" do
    context "with a pending transaction" do
      subject { build_stubbed(:transaction) }

      it { is_expected.to be_clearable }
    end

    context "with a cleared transaction" do
      subject { build_stubbed(:transaction, :cleared) }

      it { is_expected.to be_clearable }
    end

    context "with a reconciled transaction" do
      subject { build_stubbed(:transaction, :reconciled) }

      it { is_expected.not_to be_clearable }
    end

    context "with an upcoming transaction" do
      subject { build_stubbed(:transaction, :upcoming) }

      it { is_expected.not_to be_clearable }
    end
  end

  describe "#destroyable?" do
    context "with a pending transaction" do
      subject { build_stubbed(:transaction) }

      it { is_expected.to be_destroyable }
    end

    context "with a reconciled transaction" do
      subject { build_stubbed(:transaction, :reconciled) }

      it { is_expected.not_to be_destroyable }
    end

    context "with a transfer whose partner is unreconciled" do
      subject { build_stubbed(:transaction, transfer_pair: build_stubbed(:transaction)) }

      it { is_expected.to be_destroyable }
    end

    context "with a transfer whose partner is reconciled" do
      subject { build_stubbed(:transaction, transfer_pair: build_stubbed(:transaction, :reconciled)) }

      it { is_expected.not_to be_destroyable }
    end

    context "with a reconciled transfer" do
      subject { build_stubbed(:transaction, :reconciled, transfer_pair: build_stubbed(:transaction)) }

      it { is_expected.not_to be_destroyable }
    end
  end

  describe "#next_recurring_date" do
    subject { transaction.next_recurring_date }

    let(:transaction) { build(:transaction, date: Date.new(2026, 3, 15), frequency: frequency) }

    context "with a daily frequency" do
      let(:frequency) { :daily }

      it { is_expected.to eq(Date.new(2026, 3, 16)) }
    end

    context "with a weekly frequency" do
      let(:frequency) { :weekly }

      it { is_expected.to eq(Date.new(2026, 3, 22)) }
    end

    context "with an every_other_week frequency" do
      let(:frequency) { :every_other_week }

      it { is_expected.to eq(Date.new(2026, 3, 29)) }
    end

    context "with a monthly frequency" do
      let(:frequency) { :monthly }

      it { is_expected.to eq(Date.new(2026, 4, 15)) }
    end

    context "with a yearly frequency" do
      let(:frequency) { :yearly }

      it { is_expected.to eq(Date.new(2027, 3, 15)) }
    end

    context "without a frequency" do
      let(:frequency) { nil }

      it { is_expected.to be_nil }
    end

    context "with a provided frequency" do
      it "uses the provided frequency over the transaction's frequency" do
        transaction = build(:transaction, date: Date.new(2026, 3, 15), frequency: :monthly)

        expect(transaction.next_recurring_date(frequency: :daily)).to eq(Date.new(2026, 3, 16))
      end
    end
  end

  describe "#recurring_scheduled?" do
    subject { build(:transaction, date: date, frequency: frequency) }

    let(:date)      { 1.month.from_now.to_date }
    let(:frequency) { :monthly }

    context "with a frequency and a future date" do
      it { is_expected.to be_recurring_scheduled }
    end

    context "without a frequency" do
      let(:frequency) { nil }

      it { is_expected.not_to be_recurring_scheduled }
    end

    context "with a non-future date" do
      let(:date) { Date.current }

      it { is_expected.not_to be_recurring_scheduled }
    end
  end

  describe "#scheduled?" do
    subject { build(:transaction, date: date) }

    context "with a future date" do
      let(:date) { 1.day.from_now.to_date }

      it { is_expected.to be_scheduled }
    end

    context "with today's date" do
      let(:date) { Date.current }

      it { is_expected.not_to be_scheduled }
    end

    context "with a past date" do
      let(:date) { 1.day.ago.to_date }

      it { is_expected.not_to be_scheduled }
    end
  end

  describe "#transfer?" do
    context "with a transfer pair" do
      subject { build_stubbed(:transaction, transfer_pair: build_stubbed(:transaction)) }

      it { is_expected.to be_transfer }
    end

    context "without a transfer pair" do
      subject { build_stubbed(:transaction) }

      it { is_expected.not_to be_transfer }
    end
  end

  describe "#uneditable?" do
    context "with a pending transaction" do
      subject { build_stubbed(:transaction) }

      it { is_expected.not_to be_uneditable }
    end

    context "with a reconciled transaction" do
      subject { build_stubbed(:transaction, :reconciled) }

      it { is_expected.to be_uneditable }
    end

    context "with a transfer transaction" do
      subject { build_stubbed(:transaction, transfer_pair: build_stubbed(:transaction)) }

      it { is_expected.to be_uneditable }
    end
  end

  describe "#validate_subcategory" do
    subject(:transaction) { build(:transaction, subcategory: subcategory) }

    context "when valid" do
      let(:subcategory) { build_stubbed(:category, :subcategory) }

      it { is_expected.to be_valid }
    end

    context "when invalid" do
      let(:subcategory) { build_stubbed(:category) }

      it { is_expected.not_to be_valid }

      it "adds an error to subcategory" do
        transaction.valid?

        expect(transaction.errors[:subcategory]).to include(
          t("activerecord.errors.models.transaction.attributes.subcategory.not_a_subcategory")
        )
      end
    end

    context "when nil" do
      let(:subcategory) { nil }

      it { is_expected.to be_valid }
    end
  end

  describe "normalizations" do
    it "strips whitespace from the memo" do
      transaction = build(:transaction, memo: "  A note  ")

      expect(transaction.memo).to eq("A note")
    end
  end
end
