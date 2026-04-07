# frozen_string_literal: true

require "rails_helper"

describe "accounts/transactions/index.html.erb" do
  subject(:html) do
    render template: "accounts/transactions/index", formats: [:html]

    rendered
  end

  let(:account) { create(:account, budget: budget) }
  let(:budget)  { create(:budget) }

  before do
    stub_template("accounts/transactions/_actions.html.erb" => "ACTIONS_PARTIAL")
    stub_template("shared/_toolbar.html.erb"                => "TOOLBAR_PARTIAL")
    stub_template("transactions/_list.html.erb"             => "LIST_PARTIAL")

    assign :budget,                 budget
    assign :account,                account
    assign :current_transactions,   []
    assign :scheduled_transactions, []
  end

  it "renders the account name" do
    expect(html).to have_css("h1", text: account.name)
  end

  it "renders a back link to the accounts index" do
    expect(html).to have_link(href: budget_accounts_path(budget))
  end

  it "renders the working balance" do
    expect(html).to have_text(number_to_currency(Money.from_cents(account.balance)))
  end

  it "renders the cleared balance" do
    expect(html).to have_text(number_to_currency(Money.from_cents(account.cleared_balance)))
  end

  it "renders the uncleared balance" do
    expect(html).to have_text(number_to_currency(Money.from_cents(account.uncleared_balance)))
  end

  it "renders the actions partial" do
    expect(html).to include("ACTIONS_PARTIAL")
  end

  it "renders the transaction list" do
    expect(html).to include("LIST_PARTIAL")
  end

  it "renders the toolbar" do
    expect(html).to include("TOOLBAR_PARTIAL")
  end
end
