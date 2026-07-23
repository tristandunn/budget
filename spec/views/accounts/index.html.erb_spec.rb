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

  it "sets the page title" do
    html

    expect(view.content_for(:title)).to eq(t("accounts.index.title"))
  end

  it "renders the new account link" do
    expect(html).to have_link(href: new_budget_account_path(budget))
  end

  it "renders the toolbar" do
    expect(html).to include("TOOLBAR_PARTIAL")
  end

  it "renders the account dialog turbo frame" do
    expect(html).to have_css("turbo-frame#account_dialog", visible: :all)
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
        .and(have_css("li", text: number_to_money(account.balance)))
    end

    it "links the account to its transaction register" do
      expect(html).to have_link(account.name, href: budget_account_transactions_path(budget, account))
    end

    context "when there are no cash accounts" do
      before do
        assign :cash_accounts, []
      end

      it "does not render the cash section" do
        expect(html).to have_no_css("h2", text: t("accounts.index.cash"))
      end
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
        .and(have_css("li", text: number_to_money(account.balance)))
    end

    it "links the account to its transaction register" do
      expect(html).to have_link(account.name, href: budget_account_transactions_path(budget, account))
    end

    context "when there are no credit accounts" do
      before do
        assign :credit_accounts, []
      end

      it "does not render the credit section" do
        expect(html).to have_no_css("h2", text: t("accounts.index.credit"))
      end
    end
  end
end
