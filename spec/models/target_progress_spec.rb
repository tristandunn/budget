# frozen_string_literal: true

require "rails_helper"

describe TargetProgress do
  let(:snapshot) { CategorySnapshot.new(amount_assigned: assigned) }

  describe "#funded?" do
    subject { described_class.new(category: category, snapshot: snapshot).funded? }

    let(:category) { build_stubbed(:category, :with_monthly_spending_target) }

    context "when assigned is below the target" do
      let(:assigned) { category.target_amount - 100 }

      it { is_expected.to be(false) }
    end

    context "when assigned matches the target" do
      let(:assigned) { category.target_amount }

      it { is_expected.to be(true) }
    end

    context "when assigned exceeds the target" do
      let(:assigned) { category.target_amount + 100 }

      it { is_expected.to be(true) }
    end
  end

  describe "#funded_amount" do
    subject { described_class.new(category: category, snapshot: snapshot).funded_amount }

    let(:assigned) { 150_00 }
    let(:category) { build_stubbed(:category, :with_monthly_spending_target) }

    it { is_expected.to eq(150_00) }
  end

  describe "#funded_percentage" do
    subject { instance.funded_percentage }

    let(:instance) { described_class.new(category: category, snapshot: snapshot) }

    context "with a monthly_spending target where assigned is below the target" do
      let(:assigned) { 100_00 }
      let(:category) { build_stubbed(:category, target_type: :monthly_spending, target_amount: 200_00) }

      it { is_expected.to eq(50) }
    end

    context "with a monthly_spending target where assigned matches the target" do
      let(:assigned) { 200_00 }
      let(:category) { build_stubbed(:category, target_type: :monthly_spending, target_amount: 200_00) }

      it { is_expected.to eq(100) }
    end

    context "with a monthly_spending target where assigned exceeds the target" do
      let(:assigned) { 250_00 }
      let(:category) { build_stubbed(:category, target_type: :monthly_spending, target_amount: 200_00) }

      it { is_expected.to eq(100) }
    end

    context "with a monthly_spending target where assigned is negative" do
      let(:assigned) { -50_00 }
      let(:category) { build_stubbed(:category, target_type: :monthly_spending, target_amount: 200_00) }

      it { is_expected.to eq(0) }
    end

    context "when the target amount is zero" do
      let(:assigned) { 100_00 }
      let(:category) { build_stubbed(:category, target_type: :monthly_spending, target_amount: 0) }

      it { is_expected.to eq(0) }
    end
  end

  describe "#underfunded" do
    subject { instance.underfunded }

    let(:instance) { described_class.new(category: category, snapshot: snapshot) }

    context "with a monthly_spending target where assigned is below target" do
      let(:assigned) { 120_00 }
      let(:category) { build_stubbed(:category, target_type: :monthly_spending, target_amount: 200_00) }

      it { is_expected.to eq(80_00) }
    end

    context "with a monthly_spending target where assigned exceeds target" do
      let(:assigned) { 250_00 }
      let(:category) { build_stubbed(:category, target_type: :monthly_spending, target_amount: 200_00) }

      it { is_expected.to eq(0) }
    end
  end

  describe "#underfunded?" do
    subject { described_class.new(category: category, snapshot: snapshot).underfunded? }

    let(:category) { build_stubbed(:category, :with_monthly_spending_target) }

    context "when assigned is below the target" do
      let(:assigned) { category.target_amount - 100 }

      it { is_expected.to be(true) }
    end

    context "when assigned matches the target" do
      let(:assigned) { category.target_amount }

      it { is_expected.to be(false) }
    end

    context "when assigned exceeds the target" do
      let(:assigned) { category.target_amount + 100 }

      it { is_expected.to be(false) }
    end
  end
end
