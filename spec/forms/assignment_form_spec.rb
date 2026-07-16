# frozen_string_literal: true

require "rails_helper"

describe AssignmentForm, type: :form do
  it { is_expected.to be_a(BaseForm) }

  describe "#amount" do
    subject { form.amount }

    let(:form) { described_class.new(amount: amount) }

    context "when the amount is a string" do
      let(:amount) { "10 + 5" }
      let(:result) { Money.from_amount(BigDecimal("15")) }

      before do
        allow(CalculateAmount).to receive(:call).with(amount).and_return(result)
      end

      it { is_expected.to eq(result) }

      it "calculates the amount once for multiple calls" do
        2.times { form.amount }

        expect(CalculateAmount).to have_received(:call).once
      end
    end

    context "when the amount is already a Money" do
      let(:amount) { Money.from_amount(BigDecimal("10.50")) }

      before do
        allow(CalculateAmount).to receive(:call)
      end

      it { is_expected.to eq(amount) }

      it "does not calculate the amount" do
        form.amount

        expect(CalculateAmount).not_to have_received(:call)
      end
    end

    context "when the amount is nil" do
      let(:amount) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#assignment" do
    subject(:assignment) { form.assignment }

    let(:budget)      { subcategory.budget }
    let(:date)        { Date.current.beginning_of_month }
    let(:subcategory) { build_stubbed(:category, :subcategory) }

    let(:form) do
      described_class.new(amount: "25.00", budget: budget, subcategory: subcategory, date: date)
    end

    it "builds an assignment" do
      expect(assignment)
        .to be_an(Assignment)
        .and(have_attributes(amount: 2500, budget: budget, date: date, subcategory: subcategory))
    end
  end

  describe "#save" do
    subject(:save) { form.save }

    let(:budget)      { subcategory.budget }
    let(:date)        { Date.current.beginning_of_month }
    let(:subcategory) { build_stubbed(:category, :subcategory) }

    context "when valid" do
      let(:form) do
        described_class.new(
          amount:      "25.00",
          budget:      budget,
          date:        date,
          subcategory: subcategory
        )
      end

      before do
        allow(AssignCategory).to receive(:call).and_return(true)
      end

      it { is_expected.to be(true) }

      it "calls the assign category service" do
        save

        expect(AssignCategory).to have_received(:call)
          .with(budget: budget, subcategory: subcategory, amount: form.amount, date: date)
      end
    end

    context "when amount is blank" do
      let(:form) do
        described_class.new(
          amount:      "",
          budget:      budget,
          date:        date,
          subcategory: subcategory
        )
      end

      before do
        allow(AssignCategory).to receive(:call)
      end

      it { is_expected.to be_nil }

      it "does not call the assign category service" do
        save

        expect(AssignCategory).not_to have_received(:call)
      end
    end

    context "when invalid" do
      let(:form) do
        described_class.new(
          amount:      "25.00",
          budget:      budget,
          date:        date,
          subcategory: subcategory
        )
      end

      before do
        allow(AssignCategory).to receive(:call)
        form.assignment.errors.add(:amount, :invalid)
        allow(form.assignment).to receive(:valid?).and_return(false)
      end

      it { is_expected.to be_nil }

      it "does not call the assign category service" do
        save

        expect(AssignCategory).not_to have_received(:call)
      end
    end
  end

  describe "#validate_date_within_navigable_range" do
    subject(:form) do
      described_class.new(amount: "25.00", budget: budget, date: date, subcategory: subcategory).tap(&:valid?)
    end

    let(:budget)      { subcategory.budget }
    let(:subcategory) { build_stubbed(:category, :subcategory) }

    context "when the date is after the navigable range" do
      let(:date) { 5.years.from_now.to_date.beginning_of_month }

      it "adds the out-of-range error to date" do
        expect(form.errors).to be_added(:date, :out_of_range)
      end
    end

    context "when the date is before the navigable range" do
      let(:date) { 5.years.ago.to_date.beginning_of_month }

      it "adds the out-of-range error to date" do
        expect(form.errors).to be_added(:date, :out_of_range)
      end
    end

    context "when the date is within the navigable range" do
      let(:date) { Date.current.beginning_of_month }

      it "does not add an error to date" do
        expect(form.errors[:date]).to be_empty
      end
    end
  end
end
