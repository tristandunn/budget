# frozen_string_literal: true

require "rails_helper"

describe Transaction do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:budget) }
    it { is_expected.to belong_to(:subcategory).class_name("Category") }
  end

  describe "validations" do
    subject(:transaction) { create(:transaction) }

    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).only_integer }
    it { is_expected.to allow_value(1337).for(:amount) }
    it { is_expected.to allow_value(-723).for(:amount) }
    it { is_expected.not_to allow_value(0).for(:amount) }

    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:payee) }

    it "defines and validates a status enum" do
      expect(transaction).to define_enum_for(:status)
        .with_values(pending: 0, cleared: 1, reconciled: 2)
        .validating
    end

    it "defines a frequency enum" do
      expect(transaction).to define_enum_for(:frequency)
        .with_values(monthly: 0)
    end

    it "allows a nil frequency" do
      transaction.frequency = nil

      expect(transaction).to be_valid
    end
  end

  describe ".default_scope" do
    it "orders transactions by date descending" do
      newer = create(:transaction, date: Date.new(2026, 3, 15))
      older = create(:transaction, date: Date.new(2026, 3, 10), budget: newer.budget)

      expect(described_class.all).to eq([newer, older])
    end

    it "orders transactions with the same date by created_at descending" do
      first  = create(:transaction, date: Date.new(2026, 3, 15))
      second = create(:transaction, date: Date.new(2026, 3, 15), budget: first.budget)

      expect(described_class.all).to eq([second, first])
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

  describe "#validate_subcategory" do
    subject(:transaction) { build(:transaction, subcategory: subcategory) }

    context "when valid" do
      let(:subcategory) { create(:category, :subcategory) }

      it { is_expected.to be_valid }
    end

    context "when invalid" do
      let(:subcategory) { create(:category) }

      it { is_expected.not_to be_valid }

      it "adds an error to subcategory" do
        transaction.valid?

        expect(transaction.errors[:subcategory]).to include(
          I18n.t("activerecord.errors.models.transaction.attributes.subcategory.not_a_subcategory")
        )
      end
    end
  end
end
