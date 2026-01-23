# frozen_string_literal: true

require "rails_helper"

describe BudgetHelper do
  describe "#snapshot_color" do
    subject { helper.snapshot_color(snapshot) }

    let(:amount)   { 100 }
    let(:snapshot) { build(:category_snapshot, amount_assigned: amount, amount_used: amount_used) }

    context "when the amount remaining is zero" do
      let(:amount_used) { amount }

      it { is_expected.to eq("bg-stone-200 text-stone-950") }
    end

    context "when the amount remaining is negative" do
      let(:amount_used) { amount * 2 }

      it { is_expected.to eq("bg-red-200 text-red-950") }
    end

    context "when the amount remaining is positive" do
      let(:amount_used) { amount / 2 }

      it { is_expected.to eq("bg-lime-400 text-lime-950") }
    end
  end
end
