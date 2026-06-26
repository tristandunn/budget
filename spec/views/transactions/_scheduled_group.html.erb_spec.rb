# frozen_string_literal: true

require "rails_helper"

describe "transactions/_scheduled_group.html.erb" do
  subject(:html) do
    render partial: "transactions/scheduled_group", locals: {
      context:      :transactions,
      date:         date,
      transactions: [transaction]
    }

    rendered
  end

  let(:date)        { 1.month.from_now.to_date }
  let(:transaction) { build_stubbed(:transaction, :recurring, date: date, memo: "Lunch with team") }

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

  it "links to the edit page" do
    expect(html).to have_link(href: edit_budget_transaction_path(transaction.budget, transaction))
  end

  context "when not showing accounts" do
    subject(:html) do
      render partial: "transactions/scheduled_group", locals: {
        context:      :account,
        date:         date,
        transactions: [transaction]
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
    let(:transaction) { build_stubbed(:transaction, :recurring, date: date, subcategory: nil) }

    it "renders the transaction" do
      expect(html).to have_text(transaction.payee.name)
    end
  end

  context "when the transaction is a transfer" do
    let(:transaction) do
      build_stubbed(:transaction, :recurring, date: date, subcategory: nil, transfer_pair_id: 1)
    end

    it "renders the credit card payment label" do
      expect(html).to have_text(t("transactions.transfer_category"))
    end
  end
end
