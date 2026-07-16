# frozen_string_literal: true

require "rails_helper"

describe CalculateAmount do
  describe ".call" do
    subject { described_class.call(expression) }

    context "when the expression is blank" do
      let(:expression) { "" }

      it { is_expected.to be_nil }
    end

    context "when the expression is nil" do
      let(:expression) { nil }

      it { is_expected.to be_nil }
    end

    context "when the expression is zero" do
      let(:expression) { "0" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("0"))) }
    end

    context "when the expression adds to a zero left operand" do
      let(:expression) { "0.00+50.00" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("50"))) }
    end

    context "when the expression subtracts from a zero left operand" do
      let(:expression) { "0.00-13.37" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("-13.37"))) }
    end

    context "when the expression has a zero right operand" do
      let(:expression) { "100-0" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("100"))) }
    end

    context "when the expression is a decimal" do
      let(:expression) { "10.50" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("10.50"))) }
    end

    context "when the expression is comma-grouped" do
      let(:expression) { "1,000" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("1000"))) }
    end

    context "when the expression is comma-grouped with a decimal" do
      let(:expression) { "1,000.50" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("1000.50"))) }
    end

    context "when the expression has a dollar sign and comma" do
      let(:expression) { "$1,000" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("1000"))) }
    end

    context "when the expression is comma-grouped in an operation" do
      let(:expression) { "1,000+2,000" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("3000"))) }
    end

    context "when the expression is an addition" do
      let(:expression) { "100.00+13.37" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("113.37"))) }
    end

    context "when the expression is a subtraction" do
      let(:expression) { "100.00-13.37" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("86.63"))) }
    end

    context "when the expression has whitespace around a subtraction operator" do
      let(:expression) { "10 - 5" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("5"))) }
    end

    context "when the expression has whitespace around an addition operator" do
      let(:expression) { "10 + 5" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("15"))) }
    end

    context "when the expression is surrounded by whitespace" do
      let(:expression) { " 10 " }

      it { is_expected.to eq(Money.from_amount(BigDecimal("10"))) }
    end

    context "when the expression separates an operation with tabs" do
      let(:expression) { "10\t-\t5" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("5"))) }
    end

    context "when the expression contains other invalid characters" do
      let(:expression) { "10a-5" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("5"))) }
    end

    context "when the expression starts with a negative operand" do
      let(:expression) { "-50+20" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("-30"))) }
    end

    context "when the expression has a trailing operator" do
      let(:expression) { "100+" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("100"))) }
    end

    context "when the expression is a bare minus sign" do
      let(:expression) { "-" }

      it { is_expected.to be_nil }
    end

    context "when the expression is a bare plus sign" do
      let(:expression) { "+" }

      it { is_expected.to be_nil }
    end

    context "when the expression contains invalid decimal parts" do
      let(:expression) { "100+.." }

      it { is_expected.to eq(Money.from_amount(BigDecimal("100"))) }
    end

    context "when the expression chains operations" do
      let(:expression) { "100+10-5" }

      it { is_expected.to be_nil }
    end
  end
end
