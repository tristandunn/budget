# frozen_string_literal: true

require "rails_helper"

describe TransactionForm, type: :form do
  describe "class" do
    it { is_expected.to be_a(BaseForm) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:subcategory) }
  end

  describe ".from" do
    subject(:form) { described_class.from(transaction: transaction) }

    let(:transaction) { create(:transaction, amount: -1500, frequency: :monthly, memo: "Lunch") }

    it do
      expect(form).to have_attributes(
        account:     transaction.account,
        amount:      Money.from_amount(BigDecimal("-15.00")),
        budget:      transaction.budget,
        date:        transaction.date,
        frequency:   "monthly",
        memo:        "Lunch",
        payee:       transaction.payee.name,
        subcategory: transaction.subcategory
      )
    end
  end

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

      it { is_expected.to be_nil }
    end

    context "when amount is positive" do
      let(:amount) { "10.50" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("10.50"))) }
    end

    context "when amount is negative" do
      let(:amount) { "-10.50" }

      it { is_expected.to eq(Money.from_amount(BigDecimal("-10.50"))) }
    end
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

    context "when date is invalid" do
      let(:date) { "not-a-date" }

      it { is_expected.to eq(Date.current) }
    end
  end

  describe "#save" do
    subject(:save) { form.save }

    let(:account)     { create(:account, budget: subcategory.budget) }
    let(:subcategory) { create(:category, :subcategory) }

    let(:attributes) do
      {
        account:     account,
        amount:      "25.00",
        budget:      subcategory.budget,
        date:        "2026-03-18",
        memo:        "A memo",
        payee:       "Test Payee",
        subcategory: subcategory
      }
    end

    let(:form) { described_class.new(**attributes) }

    before do
      allow(CreateTransaction).to receive(:call).and_return(true)
      allow(PostRecurringTransaction).to receive(:call).and_return(true)
    end

    context "when valid" do
      it { is_expected.to be(true) }

      it "creates a transaction" do
        save

        expect(CreateTransaction).to have_received(:call).with(transaction: form.transaction)
      end

      it "does not call PostRecurringTransaction" do
        save

        expect(PostRecurringTransaction).not_to have_received(:call)
      end
    end

    context "when valid with negative amount" do
      let(:form) { described_class.new(**attributes, amount: "-25.00") }

      it { is_expected.to be(true) }

      it "creates a transaction" do
        save

        expect(CreateTransaction).to have_received(:call).with(transaction: form.transaction)
      end
    end

    context "when invalid" do
      let(:form) { described_class.new(**attributes, amount: "0") }

      it { is_expected.to be_nil }

      it "does not create a transaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end
    end

    context "when payee is blank" do
      let(:form) { described_class.new(**attributes, payee: "") }

      it { is_expected.to be_nil }

      it "does not create a transaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end
    end

    context "when subcategory is blank" do
      let(:form) { described_class.new(**attributes, subcategory: nil) }

      it { is_expected.to be_nil }

      it "adds a presence error to subcategory" do
        save

        expect(form.errors[:subcategory]).to include(t("errors.messages.blank"))
      end

      it "does not create a transaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end
    end

    context "when scheduled" do
      let(:form) do
        described_class.new(**attributes, date: 1.month.from_now.to_date.to_s)
      end

      it { is_expected.to be(true) }

      it "saves the transaction directly with upcoming status" do
        save

        expect(form.transaction).to be_persisted.and(be_upcoming)
      end

      it "does not call CreateTransaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end

      it "does not call PostRecurringTransaction" do
        save

        expect(PostRecurringTransaction).not_to have_received(:call)
      end
    end

    context "when recurring and scheduled" do
      let(:form) do
        described_class.new(**attributes, date: 1.month.from_now.to_date.to_s, frequency: "monthly")
      end

      it { is_expected.to be(true) }

      it "saves the transaction directly with upcoming status" do
        save

        expect(form.transaction).to be_persisted.and(be_upcoming)
      end

      it "does not call CreateTransaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end

      it "does not call PostRecurringTransaction" do
        save

        expect(PostRecurringTransaction).not_to have_received(:call)
      end
    end

    context "when recurring but not scheduled" do
      let(:form) do
        described_class.new(**attributes, date: Date.current.to_s, frequency: "monthly")
      end

      it { is_expected.to be(true) }

      it "calls PostRecurringTransaction" do
        save

        expect(PostRecurringTransaction).to have_received(:call).with(transaction: form.transaction)
      end

      it "does not call CreateTransaction" do
        save

        expect(CreateTransaction).not_to have_received(:call)
      end
    end
  end

  describe "#transaction" do
    subject(:transaction) { form.transaction }

    let(:account)     { create(:account, budget: subcategory.budget) }
    let(:subcategory) { create(:category, :subcategory) }

    let(:attributes) do
      {
        account:     account,
        amount:      "15.00",
        budget:      subcategory.budget,
        date:        "2026-03-18",
        memo:        "Lunch",
        payee:       "Test Payee",
        subcategory: subcategory
      }
    end

    let(:form) { described_class.new(**attributes) }

    it { is_expected.to be_a(Transaction) }

    it do
      expect(transaction).to have_attributes(
        account:     account,
        amount:      1500,
        budget:      subcategory.budget,
        date:        Date.new(2026, 3, 18),
        frequency:   nil,
        memo:        "Lunch",
        payee:       have_attributes(name: "Test Payee"),
        subcategory: subcategory
      )
    end

    it "reuses an existing payee" do
      existing = create(:payee, budget: subcategory.budget, name: attributes[:payee])

      expect(transaction.payee).to eq(existing)
    end

    it "reuses an existing payee whose name differs only in case" do
      existing = create(:payee, budget: subcategory.budget, name: attributes[:payee].upcase)

      expect(transaction.payee).to eq(existing)
    end

    it "does not persist a new payee" do
      expect { transaction }.not_to change(Payee, :count)
    end

    context "with frequency" do
      let(:form) { described_class.new(**attributes, frequency: "monthly") }

      it "sets the frequency" do
        expect(transaction.frequency).to eq("monthly")
      end
    end

    context "with blank frequency" do
      let(:form) { described_class.new(**attributes, frequency: "") }

      it "sets the frequency to nil" do
        expect(transaction.frequency).to be_nil
      end
    end

    context "with negative amount" do
      let(:form) { described_class.new(**attributes, amount: "-15.00") }

      it "sets the amount as negative cents" do
        expect(transaction.amount).to eq(-1500)
      end
    end
  end

  describe "#update" do
    subject(:update) { form.update(transaction) }

    let(:attributes) do
      {
        account:     transaction.account,
        amount:      "25.00",
        budget:      transaction.budget,
        date:        "2026-03-18",
        memo:        "A memo",
        payee:       "Test Payee",
        subcategory: transaction.subcategory
      }
    end

    let(:form)        { described_class.new(**attributes) }
    let(:transaction) { create(:transaction) }

    before do
      allow(ActivateTransaction).to receive(:call).and_return(true)
      allow(ConvertToRecurringTransaction).to receive(:call).and_return(true)
      allow(DirectUpdateTransaction).to receive(:call).and_return(true)
      allow(PostRecurringTransaction).to receive(:call).and_return(true)
      allow(SuspendTransaction).to receive(:call).and_return(true)
      allow(UpdateTransaction).to receive(:call).and_return(true)
    end

    context "when valid" do
      it { is_expected.to be(true) }

      it "calls UpdateTransaction" do
        update

        expect(UpdateTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      Date.new(2026, 3, 18),
            frequency: nil,
            payee:     an_object_having_attributes(name: "Test Payee")
          ),
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call PostRecurringTransaction" do
        update

        expect(PostRecurringTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end
    end

    context "when invalid" do
      let(:form) { described_class.new(**attributes, amount: "0") }

      it { is_expected.to be_nil }

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call PostRecurringTransaction" do
        update

        expect(PostRecurringTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when becoming recurring" do
      let(:form) do
        described_class.new(**attributes, date: 1.month.from_now.to_date.to_s, frequency: "monthly")
      end

      it { is_expected.to be(true) }

      it "calls SuspendTransaction" do
        update

        expect(SuspendTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      1.month.from_now.to_date,
            frequency: "monthly",
            payee:     an_object_having_attributes(name: "Test Payee")
          ),
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call PostRecurringTransaction" do
        update

        expect(PostRecurringTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when suspending" do
      let(:form) do
        described_class.new(**attributes, date: 1.month.from_now.to_date.to_s)
      end

      it { is_expected.to be(true) }

      it "calls SuspendTransaction" do
        update

        expect(SuspendTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      1.month.from_now.to_date,
            frequency: nil,
            payee:     an_object_having_attributes(name: "Test Payee")
          ),
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call PostRecurringTransaction" do
        update

        expect(PostRecurringTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when becoming recurring now" do
      let(:form) do
        described_class.new(**attributes, date: Date.current.to_s, frequency: "monthly")
      end

      it { is_expected.to be(true) }

      it "calls ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      Date.current,
            frequency: "monthly",
            payee:     an_object_having_attributes(name: "Test Payee")
          ),
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call PostRecurringTransaction" do
        update

        expect(PostRecurringTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when activating" do
      let(:form)        { described_class.new(**attributes) }
      let(:transaction) { create(:transaction, :recurring) }

      it { is_expected.to be(true) }

      it "calls ActivateTransaction" do
        update

        expect(ActivateTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      Date.new(2026, 3, 18),
            frequency: nil,
            payee:     an_object_having_attributes(name: "Test Payee")
          ),
          transaction: transaction
        )
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call PostRecurringTransaction" do
        update

        expect(PostRecurringTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when recurring and scheduled" do
      let(:form) do
        described_class.new(**attributes, date: 1.month.from_now.to_date.to_s, frequency: "monthly")
      end

      let(:transaction) { create(:transaction, :recurring) }

      it { is_expected.to be(true) }

      it "calls DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      1.month.from_now.to_date,
            frequency: "monthly",
            payee:     an_object_having_attributes(name: "Test Payee")
          ),
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call PostRecurringTransaction" do
        update

        expect(PostRecurringTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when posting" do
      let(:form) do
        described_class.new(**attributes, date: Date.current.to_s, frequency: "monthly")
      end

      let(:transaction) { create(:transaction, :recurring) }

      before do
        allow(transaction).to receive(:update!).and_call_original
      end

      it { is_expected.to be(true) }

      it "updates the transaction with the form attributes" do
        update

        expect(transaction).to have_received(:update!).with(
          attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      Date.current,
            frequency: "monthly",
            payee:     an_object_having_attributes(name: "Test Payee")
          )
        )
      end

      it "calls PostRecurringTransaction" do
        update

        expect(PostRecurringTransaction).to have_received(:call).with(
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when posting an upcoming non-recurring transaction with a frequency" do
      let(:form) do
        described_class.new(**attributes, date: Date.current.to_s, frequency: "monthly")
      end

      let(:transaction) { create(:transaction, :upcoming) }

      before do
        allow(transaction).to receive(:update!).and_call_original
      end

      it { is_expected.to be(true) }

      it "updates the transaction with the form attributes" do
        update

        expect(transaction).to have_received(:update!).with(
          attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      Date.current,
            frequency: "monthly",
            payee:     an_object_having_attributes(name: "Test Payee")
          )
        )
      end

      it "calls PostRecurringTransaction" do
        update

        expect(PostRecurringTransaction).to have_received(:call).with(
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when recurring but not scheduled" do
      let(:form) do
        described_class.new(**attributes, date: Date.current.to_s, frequency: "monthly")
      end

      let(:transaction) { create(:transaction, :recurring, date: Date.current) }

      before do
        allow(transaction).to receive(:update!).and_call_original
      end

      it { is_expected.to be(true) }

      it "updates the transaction with the form attributes" do
        update

        expect(transaction).to have_received(:update!).with(
          attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      Date.current,
            frequency: "monthly",
            payee:     an_object_having_attributes(name: "Test Payee")
          )
        )
      end

      it "calls PostRecurringTransaction" do
        update

        expect(PostRecurringTransaction).to have_received(:call).with(
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call ConvertToRecurringTransaction" do
        update

        expect(ConvertToRecurringTransaction).not_to have_received(:call)
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when upcoming and still scheduled" do
      let(:form) do
        described_class.new(**attributes, date: 1.month.from_now.to_date.to_s)
      end

      let(:transaction) { create(:transaction, :upcoming) }

      it { is_expected.to be(true) }

      it "calls DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      1.month.from_now.to_date,
            frequency: nil,
            payee:     an_object_having_attributes(name: "Test Payee")
          ),
          transaction: transaction
        )
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when upcoming and date moved to current" do
      let(:form)        { described_class.new(**attributes) }
      let(:transaction) { create(:transaction, :upcoming) }

      it { is_expected.to be(true) }

      it "calls ActivateTransaction" do
        update

        expect(ActivateTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      Date.new(2026, 3, 18),
            frequency: nil,
            payee:     an_object_having_attributes(name: "Test Payee")
          ),
          transaction: transaction
        )
      end

      it "does not call DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).not_to have_received(:call)
      end

      it "does not call UpdateTransaction" do
        update

        expect(UpdateTransaction).not_to have_received(:call)
      end
    end

    context "when upcoming and becoming recurring and scheduled" do
      let(:form) do
        described_class.new(**attributes, date: 1.month.from_now.to_date.to_s, frequency: "monthly")
      end

      let(:transaction) { create(:transaction, :upcoming) }

      it { is_expected.to be(true) }

      it "calls DirectUpdateTransaction" do
        update

        expect(DirectUpdateTransaction).to have_received(:call).with(
          attributes:  attributes.except(:budget, :payee).merge(
            amount:    2500,
            date:      1.month.from_now.to_date,
            frequency: "monthly",
            payee:     an_object_having_attributes(name: "Test Payee")
          ),
          transaction: transaction
        )
      end

      it "does not call SuspendTransaction" do
        update

        expect(SuspendTransaction).not_to have_received(:call)
      end

      it "does not call ActivateTransaction" do
        update

        expect(ActivateTransaction).not_to have_received(:call)
      end
    end
  end
end
