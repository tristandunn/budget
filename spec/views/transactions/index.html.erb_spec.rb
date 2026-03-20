# frozen_string_literal: true

require "rails_helper"

describe "transactions/index.html.erb" do
  subject(:html) do
    render template: "transactions/index", formats: [:html]

    rendered
  end

  let(:budget)               { create(:budget) }
  let(:grouped_transactions) { {} }

  before do
    stub_template("shared/_toolbar.html.erb" => "TOOLBAR_PARTIAL")

    assign :budget,               budget
    assign :grouped_transactions, grouped_transactions
  end

  it "renders the header" do
    expect(html).to have_css("h1", text: t("transactions.index.title"))
  end

  it "renders the toolbar" do
    expect(html).to include("TOOLBAR_PARTIAL")
  end

  context "when there are no transactions" do
    it "renders the empty state" do
      expect(html).to have_text(t("transactions.index.empty"))
    end
  end

  context "when there are transactions" do
    let(:date)                 { Date.current }
    let(:grouped_transactions) { { transaction.date => [transaction] } }
    let(:transaction)          { create(:transaction, budget: budget, date: date) }

    it "renders today for today's date" do
      expect(html).to have_css("h3", text: t("dates.today"))
    end

    context "when the date is yesterday" do
      let(:date) { Date.yesterday }

      it "renders yesterday for yesterday's date" do
        expect(html).to have_css("h3", text: t("dates.yesterday"))
      end
    end

    context "when the date is older" do
      let(:date) { 2.days.ago.to_date }

      it "renders the long date format for older dates" do
        expect(html).to have_css("h3", text: I18n.l(date, format: :long))
      end
    end

    it "renders the payee" do
      expect(html).to have_text(transaction.payee)
    end

    it "renders the amount" do
      expect(html).to have_text(number_to_currency(Money.from_cents(transaction.amount)))
    end

    it "renders the subcategory name" do
      expect(html).to have_text(transaction.subcategory.name)
    end

    it "renders the account name" do
      expect(html).to have_text(transaction.account.name)
    end
  end
end
