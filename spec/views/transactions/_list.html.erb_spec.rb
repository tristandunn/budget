# frozen_string_literal: true

require "rails_helper"

describe "transactions/_list.html.erb" do
  subject(:html) do
    render partial: "transactions/list", locals: {
      context:                :transactions,
      current_transactions:   current_transactions,
      empty_message:          empty_message,
      scheduled_id:           "account-all-scheduled",
      scheduled_transactions: scheduled_transactions
    }

    rendered
  end

  let(:current_transactions)   { [] }
  let(:empty_message)          { "No transactions yet." }
  let(:scheduled_transactions) { [] }

  context "when there are transactions" do
    let(:current_transactions) { [transaction] }
    let(:date)                 { 2.days.ago.to_date }
    let(:transaction)          { build_stubbed(:transaction, date: date, memo: "Lunch with team") }

    before do
      stub_template("transactions/_status_indicator.html.erb" => "STATUS_INDICATOR")
    end

    it "renders the date" do
      expect(html).to have_css("h3", text: I18n.l(date, format: :long))
    end

    it "renders the payee" do
      expect(html).to have_text(transaction.payee.name)
    end

    it "renders the amount" do
      expect(html).to have_text(number_to_money(transaction.amount))
    end

    it "renders the subcategory name" do
      expect(html).to have_text(transaction.subcategory.name)
    end

    it "renders the account name" do
      expect(html).to have_text(transaction.account.name)
    end

    it "does not render the memo" do
      expect(html).to have_no_text(transaction.memo)
    end

    it "renders the status indicator" do
      expect(html).to include("STATUS_INDICATOR")
    end

    it "does not render the current transaction in the scheduled section" do
      expect(html).to have_no_css("#account-all-scheduled", text: transaction.payee.name)
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
      let(:transaction) { build_stubbed(:transaction, :reconciled, date: date) }

      it "does not link to the edit page" do
        expect(html).to have_no_link(href: edit_budget_transaction_path(transaction.budget, transaction))
      end
    end

    context "when not showing accounts" do
      subject(:html) do
        render partial: "transactions/list", locals: {
          context:                :account,
          current_transactions:   current_transactions,
          empty_message:          empty_message,
          scheduled_id:           "account-all-scheduled",
          scheduled_transactions: scheduled_transactions
        }

        rendered
      end

      it "does not render the account name" do
        expect(html).to have_no_css("li span", text: transaction.account.name)
      end

      it "renders the memo" do
        expect(html).to have_text(transaction.memo)
      end
    end

    context "without a subcategory" do
      let(:transaction) { build_stubbed(:transaction, date: date, subcategory: nil) }

      it "renders the transaction" do
        expect(html).to have_text(transaction.payee.name)
      end
    end

    context "when the transaction is a transfer" do
      let(:transaction) { build_stubbed(:transaction, date: date, subcategory: nil, transfer_pair_id: 1) }

      it "renders the credit card payment label" do
        expect(html).to have_text(t("transactions.transfer_category"))
      end
    end
  end

  context "when there are scheduled transactions" do
    let(:scheduled_transactions) { [transaction] }
    let(:transaction)            { build_stubbed(:transaction, :recurring) }

    before do
      stub_template("transactions/_status_indicator.html.erb" => "STATUS_INDICATOR")
      stub_template("transactions/_scheduled_group.html.erb" => "SCHEDULED_GROUP")
    end

    it "renders the scheduled header" do
      expect(html).to have_text(t("transactions.list.scheduled"))
    end

    it "wires the scheduled section to the collapsible controller" do
      expect(html).to have_css(
        "#account-all-scheduled[data-controller='collapsible'][data-collapsible-id-value='account-all-scheduled']"
      ).and(have_css("[data-collapsible-content='collapsible-account-all-scheduled']"))
    end

    it "renders the scheduled group partial" do
      expect(html).to include("SCHEDULED_GROUP")
    end

    it "does not render the scheduled transaction in the current section" do
      expect(html).to have_no_css("#current li", text: transaction.payee.name)
    end
  end

  context "when there are no transactions" do
    it "renders the empty message" do
      expect(html).to have_text(empty_message)
    end
  end
end
