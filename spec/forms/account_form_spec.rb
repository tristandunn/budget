# frozen_string_literal: true

require "rails_helper"

describe AccountForm, type: :form do
  it { is_expected.to be_a(BaseForm) }

  describe ".from" do
    subject(:form) { described_class.from(account: account) }

    context "with a cash account" do
      let(:account) { build(:account, name: "Checking") }

      it "sets the account" do
        expect(form.account).to eq(account)
      end

      it "sets the budget" do
        expect(form.budget).to eq(account.budget)
      end

      it "sets the credit value" do
        expect(form.credit).to be(false)
      end

      it "sets the name" do
        expect(form.name).to eq("Checking")
      end
    end

    context "with a credit account" do
      let(:account) { build(:account, :credit, name: "Visa") }

      it "sets the account" do
        expect(form.account).to eq(account)
      end

      it "sets the budget" do
        expect(form.budget).to eq(account.budget)
      end

      it "sets the credit value" do
        expect(form.credit).to be(true)
      end

      it "sets the name" do
        expect(form.name).to eq("Visa")
      end
    end
  end

  describe "#persisted?" do
    subject { form.persisted? }

    context "with a persisted account" do
      let(:form) { described_class.new(account: create(:account)) }

      it { is_expected.to be(true) }
    end

    context "with an unpersisted account" do
      let(:form) { described_class.new(account: build(:account)) }

      it { is_expected.to be(false) }
    end

    context "without an account" do
      let(:form) { described_class.new }

      it { is_expected.to be(false) }
    end
  end

  describe "#save" do
    subject(:save) { form.save }

    let(:budget) { create(:budget) }

    context "when valid" do
      let(:form) { described_class.new(budget: budget, name: "Checking", credit: "false") }

      it { is_expected.to be(true) }

      it "creates the account" do
        expect { save }.to change(budget.accounts, :count).by(1)
      end

      it "assigns the account name" do
        save

        expect(form.account.name).to eq("Checking")
      end

      it "assigns the credit value" do
        save

        expect(form.account.credit).to be(false)
      end
    end

    context "when credit is true" do
      let(:form) { described_class.new(budget: budget, name: "Visa", credit: "true") }

      it "creates a credit account" do
        save

        expect(form.account.credit).to be(true)
      end
    end

    context "when invalid" do
      let(:form) { described_class.new(budget: budget, name: "", credit: "false") }

      it { is_expected.to be_nil }

      it "does not create an account" do
        expect { save }.not_to change(budget.accounts, :count)
      end

      it "merges validation errors into the form" do
        save

        expect(form.errors[:name]).to be_present
      end
    end
  end

  describe "#update" do
    subject(:update) { form.update }

    let(:account) { create(:account, name: "Old", credit: false) }

    context "when valid" do
      let(:form) { described_class.new(account: account, budget: account.budget, name: "New", credit: "true") }

      it { is_expected.to be(true) }

      it "updates the account name" do
        update

        expect(account.reload.name).to eq("New")
      end

      it "updates the credit value" do
        update

        expect(account.reload.credit).to be(true)
      end
    end

    context "when the name changes" do
      let(:form) { described_class.new(account: account, budget: account.budget, name: "New", credit: "false") }

      it "renames the inflow-side transfer payee" do
        payee = create(:payee, budget: account.budget, name: I18n.t("transfers.payee.from", account: "Old"))

        update

        expect(payee.reload.name).to eq(I18n.t("transfers.payee.from", account: "New"))
      end

      it "renames the outflow-side transfer payee" do
        payee = create(:payee, budget: account.budget, name: I18n.t("transfers.payee.to", account: "Old"))

        update

        expect(payee.reload.name).to eq(I18n.t("transfers.payee.to", account: "New"))
      end

      it "does not rename unrelated payees in the budget" do
        payee = create(:payee, budget: account.budget, name: "Grocery Store")

        update

        expect(payee.reload.name).to eq("Grocery Store")
      end

      it "does not rename matching payees in other budgets" do
        payee = create(:payee, name: I18n.t("transfers.payee.from", account: "Old"))

        update

        expect(payee.reload.name).to eq(I18n.t("transfers.payee.from", account: "Old"))
      end
    end

    context "when the name is unchanged" do
      let(:form) { described_class.new(account: account, budget: account.budget, name: "Old", credit: "true") }

      it "does not rename matching transfer payees" do
        payee = create(:payee, budget: account.budget, name: I18n.t("transfers.payee.from", account: "Old"))

        update

        expect(payee.reload.name).to eq(I18n.t("transfers.payee.from", account: "Old"))
      end
    end

    context "when invalid" do
      let(:form) { described_class.new(account: account, budget: account.budget, name: "", credit: "false") }

      it { is_expected.to be_nil }

      it "does not update the account" do
        update

        expect(account.reload.name).to eq("Old")
      end

      it "merges validation errors into the form" do
        update

        expect(form.errors[:name]).to be_present
      end
    end
  end
end
