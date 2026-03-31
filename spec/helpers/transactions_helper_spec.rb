# frozen_string_literal: true

require "rails_helper"

describe TransactionsHelper do
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

  describe "#transaction_row_wrapper" do
    context "when the transaction is not reconciled" do
      let(:transaction) { create(:transaction) }

      it "returns a link" do
        result = helper.transaction_row_wrapper(transaction) { "content" }

        expect(result).to include("href=")
      end
    end

    context "when the transaction is reconciled" do
      let(:transaction) { create(:transaction, :reconciled) }

      it "returns a div without a link" do
        result = helper.transaction_row_wrapper(transaction) { "content" }

        expect(result).not_to include("href=")
      end
    end
  end
end
