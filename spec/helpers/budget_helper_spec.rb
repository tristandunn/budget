# frozen_string_literal: true

require "rails_helper"

describe BudgetHelper do
  describe "#amount_color" do
    subject { helper.amount_color(amount) }

    context "when the amount is zero" do
      let(:amount) { 0 }

      it { is_expected.to eq("bg-stone-200 text-stone-950") }
    end

    context "when the amount is negative" do
      let(:amount) { -1 }

      it { is_expected.to eq("bg-red-200 text-red-950") }
    end

    context "when the amount is positive" do
      let(:amount) { 1 }

      it { is_expected.to eq("bg-lime-400 text-lime-950") }
    end
  end

  describe "#navigation_arrow_class" do
    subject { helper.navigation_arrow_class(disabled) }

    context "when enabled" do
      let(:disabled) { false }

      it { is_expected.to eq("h-5 w-5") }
    end

    context "when disabled" do
      let(:disabled) { true }

      it { is_expected.to eq("h-5 w-5 text-taupe-300 pointer-events-none") }
    end
  end

  describe "#picker_amount_class" do
    subject { helper.picker_amount_class(amount) }

    context "when the amount is zero" do
      let(:amount) { 0 }

      it { is_expected.to eq("text-gray-400") }
    end

    context "when the amount is negative" do
      let(:amount) { -1 }

      it { is_expected.to eq("text-gray-900") }
    end

    context "when the amount is positive" do
      let(:amount) { 1 }

      it { is_expected.to eq("text-green-600") }
    end
  end
end
