# frozen_string_literal: true

require "rails_helper"

describe Transaction do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to belong_to(:budget) }
    it { is_expected.to belong_to(:subcategory).class_name("Category") }
  end

  describe "validations" do
    subject { create(:transaction) }

    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).only_integer }
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
