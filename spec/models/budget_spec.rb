# frozen_string_literal: true

require "rails_helper"

describe Budget do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to have_many(:accounts).dependent(:destroy) }
    it { is_expected.to have_many(:categories).conditions(parent_id: nil).inverse_of(:budget).dependent(:destroy) }
    it { is_expected.to have_many(:category_snapshots).dependent(:destroy) }
    it { is_expected.to have_many(:subcategories).class_name("Category").inverse_of(:budget).dependent(:destroy) }
    it { is_expected.to have_many(:transactions).dependent(:destroy) }

    describe "#subcategories" do
      subject(:subcategories) { budget.subcategories }

      let(:budget)      { create(:budget) }
      let(:category)    { create(:category, budget: budget) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      it "returns only categories with a parent" do
        category
        subcategory

        expect(subcategories).to contain_exactly(subcategory)
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:available_to_assign).only_integer }
  end
end
