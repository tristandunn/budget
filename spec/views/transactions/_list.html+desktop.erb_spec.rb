# frozen_string_literal: true

require "rails_helper"

describe "transactions/_list.html+desktop.erb" do
  subject(:html) do
    render partial: "transactions/list", variants: [:desktop], locals: {
      context:                context,
      current_transactions:   current_transactions,
      empty_message:          empty_message,
      scheduled_transactions: scheduled_transactions
    }

    rendered
  end

  let(:context)                { :account }
  let(:current_transactions)   { [] }
  let(:empty_message)          { "No transactions yet." }
  let(:scheduled_transactions) { [] }

  before do
    stub_template("transactions/_transaction.html.erb" => "TRANSACTION_PARTIAL")
  end

  context "when there are transactions" do
    let(:current_transactions) { [build_stubbed(:transaction)] }

    it "renders the column headers" do
      expect(html).to have_css("th", text: t("transactions.list.columns.date"))
        .and(have_css("th", text: t("transactions.list.columns.payee")))
        .and(have_css("th", text: t("transactions.list.columns.category")))
        .and(have_css("th", text: t("transactions.list.columns.memo")))
        .and(have_css("th", text: t("transactions.list.columns.outflow")))
        .and(have_css("th", text: t("transactions.list.columns.inflow")))
    end

    it "labels the status column for screen readers" do
      expect(html).to have_css("th .sr-only", text: t("transactions.list.columns.status"))
    end

    it "does not render the account column header" do
      expect(html).to have_no_css("th", text: t("transactions.list.columns.account"))
    end

    it "renders the transaction partial" do
      expect(html).to include("TRANSACTION_PARTIAL")
    end

    it "does not render the scheduled header" do
      expect(html).to have_no_text(t("transactions.list.scheduled"))
    end
  end

  context "when rendered in the all-accounts context" do
    let(:context)              { :transactions }
    let(:current_transactions) { [build_stubbed(:transaction)] }

    it "renders the account column header" do
      expect(html).to have_css("th", text: t("transactions.list.columns.account"))
    end
  end

  context "when there are scheduled transactions" do
    let(:scheduled_transactions) { [build_stubbed(:transaction, :recurring)] }

    it "renders the scheduled header" do
      expect(html).to have_text(t("transactions.list.scheduled"))
    end

    it "wires the scheduled section to the collapsible controller" do
      expect(html).to have_css("tbody#scheduled[data-controller='collapsible']")
    end

    it "marks the scheduled content for the collapsible preload" do
      expect(html).to have_css("tbody[data-collapsible-content='collapsible-scheduled']")
    end

    it "renders the transaction partial" do
      expect(html).to include("TRANSACTION_PARTIAL")
    end

    it "spans the base columns in the scheduled header" do
      expect(html).to have_css("tbody#scheduled th[scope='rowgroup'][colspan='7']")
    end

    context "with the all-accounts context" do
      let(:context) { :transactions }

      it "spans the extra account column in the scheduled header" do
        expect(html).to have_css("tbody#scheduled th[scope='rowgroup'][colspan='8']")
      end
    end
  end

  context "when there are no transactions" do
    it "renders the empty message" do
      expect(html).to have_text(empty_message)
    end
  end
end
