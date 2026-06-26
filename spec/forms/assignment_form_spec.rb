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

    context "when amount is comma-grouped" do
      let(:amount) { "1,000" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("1000"))) }
    end

    context "when amount is comma-grouped with a decimal" do
      let(:amount) { "1,000.50" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("1000.50"))) }
    end

    context "when amount has a dollar sign and comma" do
      let(:amount) { "$1,000" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("1000"))) }
    end

    context "when amount is comma-grouped in an expression" do
      let(:amount) { "1,000+2,000" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("3000"))) }
    end

    context "when amount is an addition expression" do
      let(:amount) { "100.00+13.37" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("113.37"))) }
    end

    context "when amount is a subtraction expression" do
      let(:amount) { "100.00-13.37" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("86.63"))) }
    end

    context "when amount is a chained expression" do
      let(:amount) { "100+10-5" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("105"))) }
    end

    context "when amount starts with a negative part" do
      let(:amount) { "-50+20" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("-30"))) }
    end

    context "when amount has a trailing operator" do
      let(:amount) { "100+" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("100"))) }
    end

    context "when amount is a bare minus sign" do
      let(:amount) { "-" }

      it { is_expected.to be_nil }
    end

    context "when amount is a bare plus sign" do
      let(:amount) { "+" }

      it { is_expected.to be_nil }
    end

    context "when amount contains invalid decimal parts" do
      let(:amount) { "100+.." }

      it { is_expected.to eq(Money.from_amount(BigDecimal("100"))) }
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
