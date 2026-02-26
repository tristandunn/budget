# frozen_string_literal: true

require "rails_helper"

describe AssignmentForm, type: :form do
  it { is_expected.to be_a(BaseForm) }

  describe "#amount" do
    subject { form.amount }

    let(:form) { described_class.new(amount: amount) }

    context "when amount is blank" do
      let(:amount) { "" }

      it { is_expected.to be_nil }
    end

    context "when amount is nil" do
      let(:amount) { nil }

      it { is_expected.to be_nil }
    end

    context "when amount is zero" do
      let(:amount) { "0" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("0"))) }
    end

    context "when amount is positive" do
      let(:amount) { "10.50" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("10.50"))) }
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
    let(:subcategory) { create(:category, :subcategory) }

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
end
