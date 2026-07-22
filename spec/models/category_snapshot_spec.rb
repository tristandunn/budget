# frozen_string_literal: true

require "rails_helper"

describe CategorySnapshot do
  describe "class" do
    it { is_expected.to be_a(ApplicationRecord) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:budget) }
    it { is_expected.to belong_to(:category) }
  end

  describe "validations" do
    subject { create(:category_snapshot) }

    it { is_expected.to validate_numericality_of(:amount_assigned).only_integer }

    it { is_expected.to validate_numericality_of(:amount_used).only_integer }

    it { is_expected.to validate_uniqueness_of(:category_id).scoped_to(:budget_id, :date) }

    it { is_expected.to validate_presence_of(:date) }
  end

  describe ".for_month" do
    it "returns snapshots matching the given month" do
      matching = create(:category_snapshot, date: Date.current.beginning_of_month)
      create(:category_snapshot, date: 1.month.from_now.beginning_of_month)

      expect(described_class.for_month(Date.current)).to contain_exactly(matching)
    end
  end

  describe "#amount_remaining" do
    subject { category_snapshot.amount_remaining }

    let(:amount_assigned)   { 100 }
    let(:amount_used)       { 33 }
    let(:category_snapshot) { create(:category_snapshot, amount_assigned: amount_assigned, amount_used: amount_used) }

    it { is_expected.to eq(67) }
  end

  describe "#snoozed?" do
    subject { category_snapshot.snoozed? }

    context "when metadata is empty" do
      let(:category_snapshot) { build(:category_snapshot, metadata: {}) }

      it { is_expected.to be(false) }
    end

    context "when metadata snoozed is false" do
      let(:category_snapshot) { build(:category_snapshot, metadata: { "snoozed" => false }) }

      it { is_expected.to be(false) }
    end

    context "when metadata snoozed is true" do
      let(:category_snapshot) { build(:category_snapshot, metadata: { "snoozed" => true }) }

      it { is_expected.to be(true) }
    end
  end
end
