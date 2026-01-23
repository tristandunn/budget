# frozen_string_literal: true

require "rails_helper"

describe CategorySnapshot do
  it { is_expected.to be_a(ApplicationRecord) }

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

  describe "#amount_remaining" do
    subject { category_snapshot.amount_remaining }

    let(:amount_assigned)   { 100 }
    let(:amount_used)       { 33 }
    let(:category_snapshot) { create(:category_snapshot, amount_assigned: amount_assigned, amount_used: amount_used) }

    it { is_expected.to eq(67) }
  end
end
