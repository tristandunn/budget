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

  describe "#available_color" do
    subject { helper.available_color(category, budget_snapshot) }

    let(:available) { 100_00 }
    let(:category)  { build_stubbed(:category, :subcategory) }

    let(:budget_snapshot) do
      instance_double(BudgetSnapshot, available_for: available, underfunded?: underfunded)
    end

    before do
      allow(helper).to receive(:amount_color).with(available).and_return("AMOUNT_COLOR")
    end

    context "when the category is underfunded" do
      let(:underfunded) { true }

      it { is_expected.to eq("bg-yellow-200 text-yellow-950") }
    end

    context "when the category is not underfunded" do
      let(:underfunded) { false }

      it { is_expected.to eq("AMOUNT_COLOR") }
    end
  end

  describe "#month_progress_label" do
    subject { helper.month_progress_label(snapshot) }

    context "when the month is fully funded" do
      let(:snapshot) { instance_double(BudgetSnapshot, funded?: true, date: Date.new(2026, 7, 1)) }

      it { is_expected.to eq(t("budgets.show.future_funded", month: "July")) }
    end

    context "when the month is not fully funded" do
      let(:snapshot) do
        instance_double(BudgetSnapshot, funded?: false, funded_percentage: 75, date: Date.new(2026, 7, 1))
      end

      it { is_expected.to eq(t("budgets.show.future_progress", month: "July", percentage: 75)) }
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

  describe "#progress_color" do
    subject { helper.progress_color(progress) }

    let(:progress) { instance_double(TargetProgress, funded?: funded) }

    context "when the progress is funded" do
      let(:funded) { true }

      it { is_expected.to eq("text-lime-500") }
    end

    context "when the progress is not funded" do
      let(:funded) { false }

      it { is_expected.to eq("text-yellow-500") }
    end
  end

  describe "#progress_label" do
    subject { helper.progress_label(progress) }

    let(:progress) { instance_double(TargetProgress, funded?: funded, funded_percentage: 75) }

    context "when the progress is funded" do
      let(:funded) { true }

      it { is_expected.to eq(t("categories.show.target.funded_label")) }
    end

    context "when the progress is not funded" do
      let(:funded) { false }

      it { is_expected.to eq(t("categories.show.target.percent_funded", percentage: 75)) }
    end
  end
end
