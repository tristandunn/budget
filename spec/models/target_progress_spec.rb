# frozen_string_literal: true

require "rails_helper"

describe TargetProgress do
  let(:rollover) { 0 }
  let(:snapshot) { CategorySnapshot.new(amount_assigned: assigned) }

  describe "#funded?" do
    subject { described_class.new(category: category, rollover: rollover, snapshot: snapshot).funded? }

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

    context "when rollover plus assigned matches the target" do
      let(:assigned) { category.target_amount - 14_06 }
      let(:rollover) { 14_06 }

      it { is_expected.to be(true) }
    end

    context "when a negative rollover keeps assigned below the target" do
      let(:assigned) { category.target_amount }
      let(:rollover) { -50_00 }

      it { is_expected.to be(false) }
    end
  end

  describe "#funded_amount" do
    subject { described_class.new(category: category, rollover: rollover, snapshot: snapshot).funded_amount }

    let(:assigned) { 150_00 }
    let(:category) { build_stubbed(:category, :with_monthly_spending_target) }

    it { is_expected.to eq(150_00) }

    context "with a positive rollover" do
      let(:assigned) { 985_94 }
      let(:rollover) { 14_06 }

      it { is_expected.to eq(1_000_00) }
    end

    context "with a negative rollover" do
      let(:rollover) { -50_00 }

      it { is_expected.to eq(100_00) }
    end
  end

  describe "#funded_percentage" do
    subject { instance.funded_percentage }

    let(:category) { build_stubbed(:category, target_type: :monthly_spending, target_amount: 200_00) }
    let(:instance) { described_class.new(category: category, rollover: rollover, snapshot: snapshot) }

    context "with a monthly_spending target where assigned is below the target" do
      let(:assigned) { 100_00 }

      it { is_expected.to eq(50) }
    end

    context "with a monthly_spending target where assigned matches the target" do
      let(:assigned) { 200_00 }

      it { is_expected.to eq(100) }
    end

    context "with a monthly_spending target where assigned exceeds the target" do
      let(:assigned) { 250_00 }

      it { is_expected.to eq(100) }
    end

    context "with a monthly_spending target where assigned is negative" do
      let(:assigned) { -50_00 }

      it { is_expected.to eq(0) }
    end

    context "when the target amount is zero" do
      let(:assigned) { 100_00 }
      let(:category) { build_stubbed(:category, target_type: :monthly_spending, target_amount: 0) }

      it { is_expected.to eq(0) }
    end

    context "with a positive rollover that completes the target" do
      let(:assigned) { 100_00 }
      let(:rollover) { 100_00 }

      it { is_expected.to eq(100) }
    end

    context "with a negative rollover that lowers the funded percentage" do
      let(:assigned) { 150_00 }
      let(:rollover) { -50_00 }

      it { is_expected.to eq(50) }
    end
  end

  describe "#underfunded" do
    subject { instance.underfunded }

    let(:category) { build_stubbed(:category, target_type: :monthly_spending, target_amount: 200_00) }
    let(:instance) { described_class.new(category: category, rollover: rollover, snapshot: snapshot) }

    context "with a monthly_spending target where assigned is below target" do
      let(:assigned) { 120_00 }

      it { is_expected.to eq(80_00) }
    end

    context "with a monthly_spending target where assigned exceeds target" do
      let(:assigned) { 250_00 }

      it { is_expected.to eq(0) }
    end

    context "with a positive rollover that reduces the amount to go" do
      let(:assigned) { 100_00 }
      let(:rollover) { 80_00 }

      it { is_expected.to eq(20_00) }
    end

    context "with a negative rollover that increases the amount to go" do
      let(:assigned) { 200_00 }
      let(:rollover) { -50_00 }

      it { is_expected.to eq(50_00) }
    end
  end

  describe "#underfunded?" do
    subject { described_class.new(category: category, rollover: rollover, snapshot: snapshot).underfunded? }

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

    context "when a positive rollover completes an underfunded target" do
      let(:assigned) { category.target_amount - 100 }
      let(:rollover) { 100 }

      it { is_expected.to be(false) }
    end

    context "when a negative rollover keeps a fully assigned target underfunded" do
      let(:assigned) { category.target_amount }
      let(:rollover) { -100 }

      it { is_expected.to be(true) }
    end
  end
end
