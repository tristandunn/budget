# frozen_string_literal: true

require "rails_helper"

describe TransactionsHelper do
  describe "#account_reconciled_summary" do
    subject { helper.account_reconciled_summary(account) }

    let(:account) { build_stubbed(:account) }

    context "when the account has been reconciled" do
      before do
        allow(account).to receive(:last_reconciled_at).and_return(Time.current)
      end

      it { is_expected.to eq(t("accounts.transactions.reconcile.reconciled", time: t("dates.today").downcase)) }
    end

    context "when the account has never been reconciled" do
      before do
        allow(account).to receive(:last_reconciled_at).and_return(nil)
      end

      it { is_expected.to eq(t("accounts.transactions.reconcile.reconciled_never")) }
    end
  end

  describe "#relative_date" do
    it "returns today for the current date" do
      expect(helper.relative_date(Date.current)).to eq(t("dates.today"))
    end

    it "returns yesterday for yesterday's date" do
      expect(helper.relative_date(Date.yesterday)).to eq(t("dates.yesterday"))
    end

    it "returns the long date format for older dates" do
      date = 2.days.ago.to_date

      expect(helper.relative_date(date)).to eq(I18n.l(date, format: :long))
    end
  end

  describe "#relative_time" do
    it "returns today for the current date" do
      expect(helper.relative_time(Date.current)).to eq("today")
    end

    it "returns yesterday for yesterday's date" do
      expect(helper.relative_time(Date.yesterday)).to eq("yesterday")
    end

    it "returns days ago for 2-6 days" do
      expect(helper.relative_time(3.days.ago.to_date)).to eq("3 days ago")
    end

    it "returns 1 week ago for 7 days" do
      expect(helper.relative_time(7.days.ago.to_date)).to eq("1 week ago")
    end

    it "rounds weeks ago to the nearest week" do
      expect(helper.relative_time(11.days.ago.to_date)).to eq("2 weeks ago")
    end

    it "returns pluralized weeks ago for 14-27 days" do
      expect(helper.relative_time(14.days.ago.to_date)).to eq("2 weeks ago")
    end

    it "rounds weeks ago up at the end of the range" do
      expect(helper.relative_time(27.days.ago.to_date)).to eq("4 weeks ago")
    end

    it "returns months ago at the boundary of 28 days" do
      expect(helper.relative_time(28.days.ago.to_date)).to eq("1 month ago")
    end

    it "returns months ago for 30 days" do
      expect(helper.relative_time(30.days.ago.to_date)).to eq("1 month ago")
    end

    it "rounds months ago down just past the boundary" do
      expect(helper.relative_time(31.days.ago.to_date)).to eq("1 month ago")
    end

    it "rounds months ago down below the midpoint" do
      expect(helper.relative_time(45.days.ago.to_date)).to eq("1 month ago")
    end

    it "returns pluralized months ago for 60+ days" do
      expect(helper.relative_time(60.days.ago.to_date)).to eq("2 months ago")
    end

    it "rounds months ago to the nearest month past 60 days" do
      expect(helper.relative_time(61.days.ago.to_date)).to eq("2 months ago")
    end
  end

  describe "#transaction_category" do
    context "when the transaction is a transfer" do
      let(:transaction) { build_stubbed(:transaction, transfer_pair_id: 1) }

      it "returns the credit card payment label" do
        expect(helper.transaction_category(transaction)).to eq(t("transactions.transfer_category"))
      end
    end

    context "when the transaction has a subcategory" do
      let(:transaction) { build_stubbed(:transaction) }

      it "returns the subcategory name" do
        expect(helper.transaction_category(transaction)).to eq(transaction.subcategory.name)
      end
    end

    context "when the transaction has no subcategory" do
      let(:transaction) { build_stubbed(:transaction, subcategory: nil) }

      it "returns nil" do
        expect(helper.transaction_category(transaction)).to be_nil
      end
    end
  end

  describe "#transaction_row_wrapper" do
    context "when the transaction is not reconciled" do
      let(:transaction) { build_stubbed(:transaction) }

      it "returns a link" do
        result = helper.transaction_row_wrapper(transaction) { "content" }

        expect(result).to include("href=")
      end

      it "targets the transaction dialog frame" do
        result = helper.transaction_row_wrapper(transaction) { "content" }

        expect(result).to include(%(data-turbo-frame="transaction_dialog"))
      end
    end

    context "when the transaction is reconciled" do
      let(:transaction) { build_stubbed(:transaction, :reconciled) }

      it "returns a div without a link" do
        result = helper.transaction_row_wrapper(transaction) { "content" }

        expect(result).not_to include("href=")
      end
    end
  end
end
