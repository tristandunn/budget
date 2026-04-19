# frozen_string_literal: true

require "rails_helper"

describe "accounts/index.html.erb" do
  subject(:html) do
    render template: "accounts/index", formats: [:html]

    rendered
  end

  let(:budget) { build_stubbed(:budget) }

  before do
    stub_template("shared/_toolbar.html.erb" => "TOOLBAR_PARTIAL")

    assign :budget,          budget
    assign :cash_accounts,   []
    assign :credit_accounts, []
  end

  it "renders the header" do
    expect(html).to have_css("h1", text: t("accounts.index.title"))
  end

  it "renders the toolbar" do
    expect(html).to include("TOOLBAR_PARTIAL")
  end

  describe "cash section" do
    let(:account) { build_stubbed(:account, budget: budget) }

    before do
      assign :cash_accounts, [account]
    end

    it "renders the account with its balance" do
      expect(html).to have_css("h2", text: t("accounts.index.cash"))
        .and(have_text(t("accounts.index.available")))
        .and(have_css("li", text: account.name))
        .and(have_css("li", text: number_to_currency(Money.from_cents(account.balance))))
    end

    it "links the account to its transaction register" do
      expect(html).to have_link(account.name, href: budget_account_transactions_path(budget, account))
    end
  end

  describe "credit section" do
    let(:account) { build_stubbed(:account, :credit, budget: budget) }

    before do
      assign :credit_accounts, [account]
    end

    it "renders the account with its balance" do
      expect(html).to have_css("h2", text: t("accounts.index.credit"))
        .and(have_text(t("accounts.index.owed")))
        .and(have_css("li", text: account.name))
        .and(have_css("li", text: number_to_currency(Money.from_cents(account.balance))))
    end

    it "links the account to its transaction register" do
      expect(html).to have_link(account.name, href: budget_account_transactions_path(budget, account))
    end
  end
end
