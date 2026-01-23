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
end
