# frozen_string_literal: true

require "rails_helper"

describe Category do
  describe "class" do
    it { is_expected.to be_a(ApplicationRecord) }
  end

  describe "associations" do
    subject(:category) { build(:category) }

    it { is_expected.to belong_to(:budget) }
    it { is_expected.to belong_to(:parent).class_name("Category").optional(true) }

    it { is_expected.to have_many(:snapshots).class_name("CategorySnapshot").dependent(:destroy) }

    it "has many subcategories" do
      expect(category).to have_many(:subcategories)
        .class_name("Category")
        .with_foreign_key(:parent_id)
        .inverse_of(:parent)
        .dependent(:destroy)
    end

    it { is_expected.to have_many(:transactions).inverse_of(:subcategory).dependent(:nullify) }
  end

  describe "validations" do
    subject(:category) { create(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:budget_id, :parent_id).case_insensitive }

    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_numericality_of(:position).only_integer }

    context "when target_type is monthly_spending" do
      subject { build(:category, :subcategory, target_type: :monthly_spending, target_amount: 100_00) }

      it { is_expected.to validate_presence_of(:target_amount) }
      it { is_expected.to validate_numericality_of(:target_amount).only_integer.is_greater_than(0) }
    end

    context "when target_type is monthly_savings" do
      subject { build(:category, :subcategory, target_type: :monthly_savings, target_amount: 100_00) }

      it { is_expected.to validate_presence_of(:target_amount) }
      it { is_expected.to validate_numericality_of(:target_amount).only_integer.is_greater_than(0) }
    end

    context "when target_type is blank" do
      subject { build(:category, :subcategory, target_type: nil, target_amount: nil) }

      it { is_expected.to be_valid }
    end

    it "defines and validates a target_type enum" do
      expect(category).to define_enum_for(:target_type)
        .with_values(monthly_spending: 0, monthly_savings: 1)
        .with_prefix(:target_type)
        .validating(allowing_nil: true)
    end
  end

  describe ".with_monthly_target" do
    it "returns categories with a monthly target and excludes those without" do
      spending = create(:category, :subcategory, :with_monthly_spending_target, with_snapshot: false)
      savings  = create(:category, :subcategory, :with_monthly_savings_target, with_snapshot: false)
      create(:category, :subcategory, with_snapshot: false)

      expect(described_class.with_monthly_target).to contain_exactly(spending, savings)
    end
  end

  describe "#inflow?" do
    Category::INFLOW_NAMES.each do |name|
      it "returns true for a category named #{name}" do
        category = build(:category, name: name)

        expect(category).to be_inflow
      end
    end

    it "returns true regardless of case" do
      category = build(:category, name: Category::INFLOW.upcase)

      expect(category).to be_inflow
    end

    it "returns false for a regular category" do
      category = build(:category, name: "Groceries")

      expect(category).not_to be_inflow
    end
  end

  describe "#monthly_target?" do
    it "returns true for a monthly_spending target" do
      category = build(:category, target_type: :monthly_spending)

      expect(category).to be_monthly_target
    end

    it "returns true for a monthly_savings target" do
      category = build(:category, target_type: :monthly_savings)

      expect(category).to be_monthly_target
    end

    it "returns false without a target" do
      category = build(:category, target_type: nil)

      expect(category).not_to be_monthly_target
    end
  end

  describe "#subcategories_by_position" do
    it "returns subcategories sorted by position" do
      category = create(:category, with_snapshot: false)
      second   = create(:category, parent: category, budget: category.budget, position: 2, with_snapshot: false)
      first    = create(:category, parent: category, budget: category.budget, position: 1, with_snapshot: false)

      expect(category.subcategories_by_position).to eq([first, second])
    end
  end

  describe "normalizations" do
    it "strips whitespace from the name" do
      category = build(:category, name: "  Groceries  ")

      expect(category.name).to eq("Groceries")
    end
  end
end
