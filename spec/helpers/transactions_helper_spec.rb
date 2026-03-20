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
end
