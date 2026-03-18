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
    let(:grouped_transactions) { { transaction.date => [transaction] } }
    let(:transaction)          { create(:transaction, budget: budget) }

    it "renders the date header" do
      expect(html).to have_css("h3", text: I18n.l(transaction.date, format: :long))
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
