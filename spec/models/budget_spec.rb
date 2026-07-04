# frozen_string_literal: true

require "rails_helper"

describe Budget do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to have_many(:accounts).dependent(:destroy) }
    it { is_expected.to have_many(:categories).conditions(parent_id: nil).inverse_of(:budget).dependent(:destroy) }
    it { is_expected.to have_many(:category_snapshots).dependent(:destroy) }
    it { is_expected.to have_many(:memberships).dependent(:destroy) }
    it { is_expected.to have_many(:payees).dependent(:destroy) }
    it { is_expected.to have_many(:subcategories).class_name("Category").inverse_of(:budget).dependent(:destroy) }
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:memberships) }

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
    it { is_expected.to validate_presence_of(:users).on(:create) }
  end

  describe "#assignable_categories" do
    let(:budget) { create(:budget) }

    it "returns non-inflow top-level categories sorted by position" do
      create(:category, budget: budget, name: Category::INFLOW, position: 0)
      second = create(:category, budget: budget, position: 2)
      first  = create(:category, budget: budget, position: 1)

      expect(budget.assignable_categories).to eq([first, second])
    end
  end

  describe "#balance" do
    let(:budget) { create(:budget) }

    it "returns the combined balance of every account" do
      create(:account, budget: budget, balance: 100_00)
      create(:account, budget: budget, balance: -25_00)

      expect(budget.balance).to eq(75_00)
    end

    it "memoizes the combined balance" do
      allow(budget.accounts).to receive(:sum).and_call_original

      budget.balance
      budget.balance

      expect(budget.accounts).to have_received(:sum).once
    end
  end

  describe "#cleared_balance" do
    let(:budget) { create(:budget) }

    it "returns the combined balance minus pending transaction amounts" do
      account = create(:account, budget: budget, balance: -90_00)
      create(:transaction, account: account, amount: -20_00, budget: budget)
      create(:transaction, :cleared, account: account, amount: -40_00, budget: budget)

      expect(budget.cleared_balance).to eq(-70_00)
    end
  end

  describe "#settings" do
    subject { budget.settings }

    let(:budget)   { build(:budget) }
    let(:settings) { instance_double(Settings) }

    before do
      allow(Settings).to receive(:new).with(budget).and_return(settings)
    end

    it { is_expected.to eq(settings) }
  end

  describe "#uncleared_balance" do
    let(:budget) { create(:budget) }

    it "returns the combined sum of pending transaction amounts" do
      account = create(:account, budget: budget)
      create(:transaction, account: account, amount: -50_00, budget: budget)
      create(:transaction, :cleared, account: account, amount: -30_00, budget: budget)

      expect(budget.uncleared_balance).to eq(-50_00)
    end

    it "memoizes the combined uncleared balance" do
      allow(budget.transactions).to receive(:pending).and_call_original

      budget.uncleared_balance
      budget.uncleared_balance

      expect(budget.transactions).to have_received(:pending).once
    end
  end
end
