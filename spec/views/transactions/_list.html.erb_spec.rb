# frozen_string_literal: true

require "rails_helper"

describe "transactions/_list.html.erb" do
  subject(:html) do
    render partial: "transactions/list", locals: {
      grouped_transactions: grouped_transactions,
      empty_message:        empty_message
    }

    rendered
  end

  let(:empty_message) { "No transactions yet." }

  context "when there are transactions" do
    let(:date)                 { 2.days.ago.to_date }
    let(:grouped_transactions) { { transaction.date => [transaction] } }
    let(:transaction)          { create(:transaction, date: date) }

    before do
      stub_template("transactions/_status_indicator.html.erb" => "STATUS_INDICATOR")
    end

    it "renders the date" do
      expect(html).to have_css("h3", text: I18n.l(date, format: :long))
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

    it "renders the status indicator" do
      expect(html).to include("STATUS_INDICATOR")
    end

    it "links each transaction to its edit page" do
      expected = edit_budget_transaction_path(transaction.budget, transaction)

      expect(html).to have_link(href: expected)
    end

    context "when the date is today" do
      let(:date) { Date.current }

      it "renders today for the date" do
        expect(html).to have_css("h3", text: t("dates.today"))
      end
    end

    context "when the date is yesterday" do
      let(:date) { Date.yesterday }

      it "renders yesterday for the date" do
        expect(html).to have_css("h3", text: t("dates.yesterday"))
      end
    end

    context "when the transaction is reconciled" do
      let(:transaction) { create(:transaction, :reconciled, date: date) }

      it "does not link to the edit page" do
        expect(html).to have_no_link(href: edit_budget_transaction_path(transaction.budget, transaction))
      end
    end

    context "when not showing accounts" do
      subject(:html) do
        render partial: "transactions/list", locals: {
          grouped_transactions: grouped_transactions,
          empty_message:        empty_message,
          show_account:         false
        }

        rendered
      end

      it "does not render the account name" do
        expect(html).to have_no_css("li span", text: transaction.account.name)
      end
    end
  end

  context "when there are no transactions" do
    let(:grouped_transactions) { {} }

    it "renders the empty message" do
      expect(html).to have_text(empty_message)
    end
  end
end
