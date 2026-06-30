# frozen_string_literal: true

require "rails_helper"

describe TransferForm, type: :form do
  it { is_expected.to be_a(BaseForm) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:from_account) }
    it { is_expected.to validate_presence_of(:to_account) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0).allow_blank }
  end

  describe "#date" do
    subject { form.date }

    let(:form) { described_class.new(date: date) }

    context "when date is a valid string" do
      let(:date) { "2026-03-18" }

      it { is_expected.to eq(Date.new(2026, 3, 18)) }
    end

    context "when date is blank" do
      let(:date) { "" }

      it { is_expected.to eq(Date.current) }
    end

    context "when date is nil" do
      let(:date) { nil }

      it { is_expected.to eq(Date.current) }
    end

    context "when date is unparseable" do
      let(:date) { "not-a-date" }

      it { is_expected.to eq(Date.current) }
    end
  end

  describe "#default_amount" do
    subject { form.default_amount }

    context "when there is no destination account" do
      let(:form) { described_class.new }

      it { is_expected.to be_nil }
    end

    context "when the destination is a cash account" do
      let(:form) { described_class.new(to_account: create(:account)) }

      it { is_expected.to be_nil }
    end

    context "when the destination credit account has a balance owed" do
      let(:form) { described_class.new(to_account: create(:account, :credit, balance: -7000)) }

      it { is_expected.to eq("70.00") }
    end

    context "when the destination credit account is overpaid" do
      let(:form) { described_class.new(to_account: create(:account, :credit, balance: 5000)) }

      it { is_expected.to eq("0.00") }
    end
  end

  describe "#save" do
    subject(:save) { form.save }

    let(:budget)       { create(:budget) }
    let(:from_account) { create(:account, budget: budget) }
    let(:to_account)   { create(:account, :credit, budget: budget) }

    let(:attributes) do
      {
        amount:       "50.00",
        budget:       budget,
        date:         "2026-04-15",
        from_account: from_account,
        memo:         "Move money",
        to_account:   to_account
      }
    end

    let(:form) { described_class.new(**attributes) }

    before do
      allow(CreateTransfer).to receive(:call).and_return(true)
    end

    context "when valid" do
      it { is_expected.to be(true) }

      it "calls CreateTransfer with the parsed attributes" do
        save

        expect(CreateTransfer).to have_received(:call).with(
          accounts: { from: from_account, to: to_account },
          amount:   Money.from_amount(BigDecimal("50.00")),
          budget:   budget,
          date:     Date.new(2026, 4, 15),
          memo:     "Move money"
        )
      end
    end

    context "when memo is blank" do
      let(:form) { described_class.new(**attributes, memo: "") }

      it "passes nil as the memo" do
        save

        expect(CreateTransfer).to have_received(:call).with(hash_including(memo: nil))
      end
    end

    context "when invalid" do
      let(:form) { described_class.new(**attributes, amount: "0") }

      it { is_expected.to be_nil }

      it "does not call CreateTransfer" do
        save

        expect(CreateTransfer).not_to have_received(:call)
      end
    end
  end

  describe "#valid?" do
    context "when from_account and to_account refer to the same record" do
      subject(:form) { described_class.new(from_account: account, to_account: account).tap(&:valid?) }

      let(:account) { create(:account) }

      it "adds the must-not-match error to to_account" do
        expect(form.errors).to be_added(:to_account, :must_not_match_source)
      end
    end

    context "when from_account is a credit account" do
      subject(:form) { described_class.new(from_account: from_account).tap(&:valid?) }

      let(:from_account) { create(:account, :credit) }

      it "adds the must-be-cash error to from_account" do
        expect(form.errors).to be_added(:from_account, :must_be_cash)
      end
    end

    context "when to_account is a cash account" do
      subject(:form) { described_class.new(to_account: to_account).tap(&:valid?) }

      let(:to_account) { create(:account) }

      it "adds the must-be-credit error to to_account" do
        expect(form.errors).to be_added(:to_account, :must_be_credit)
      end
    end

    context "when the date is in the future" do
      subject(:form) { described_class.new(date: Date.tomorrow.iso8601).tap(&:valid?) }

      it "adds the in-the-future error to date" do
        expect(form.errors).to be_added(:date, :in_the_future)
      end
    end

    context "when the date is today" do
      subject(:form) { described_class.new(date: Date.current.iso8601).tap(&:valid?) }

      it "does not add an error to date" do
        expect(form.errors[:date]).to be_empty
      end
    end

    context "when the date is in the past" do
      subject(:form) { described_class.new(date: Date.yesterday.iso8601).tap(&:valid?) }

      it "does not add an error to date" do
        expect(form.errors[:date]).to be_empty
      end
    end
  end
end
