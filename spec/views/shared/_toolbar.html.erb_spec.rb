# frozen_string_literal: true

require "rails_helper"

describe "shared/_toolbar.html.erb" do
  subject(:html) do
    render partial: "shared/toolbar",
           locals:  { budget: budget, account_id: account_id }

    rendered
  end

  let(:account_id) { nil }
  let(:budget)     { build_stubbed(:budget) }

  it "renders the plan link" do
    expect(html).to have_link(t("toolbar.plan"), href: budget_path(budget))
  end

  it "renders the spending link" do
    expect(html).to have_link(t("toolbar.spending"), href: budget_transactions_path(budget))
  end

  it "renders the accounts link" do
    expect(html).to have_link(t("toolbar.accounts"), href: budget_accounts_path(budget))
  end

  it "renders the reflect link" do
    expect(html).to have_link(t("toolbar.reflect"), href: root_path)
  end

  it "renders the transaction dialog" do
    expect(html).to have_css("dialog.dialog[aria-labelledby='transaction_dialog_title']")
  end

  it "renders the transaction dialog turbo frame" do
    expect(html).to have_css("dialog turbo-frame#transaction_dialog")
  end

  it "renders the add transaction link targeting the dialog frame" do
    path = new_budget_transaction_path(budget)

    expect(html).to have_css(%(a[href="#{path}"][data-turbo-frame="transaction_dialog"]))
  end

  it "renders the add transaction link with an accessible label" do
    expect(html).to have_css(%(a#add-transaction[aria-label="#{t("toolbar.add_transaction")}"]))
  end

  context "with an account ID" do
    let(:account)    { build_stubbed(:account, budget: budget) }
    let(:account_id) { account.id }

    it "renders the add transaction link with the account" do
      expect(html).to have_link(href: new_budget_transaction_path(budget, account_id: account.id))
    end
  end

  context "when on the budgets controller" do
    before do
      allow(view).to receive(:controller_name).and_return("budgets")
    end

    it "renders the plan link as active" do
      expect(html).to have_link(t("toolbar.plan"), class: "text-taupe-800")
    end

    it "renders the spending link as inactive" do
      expect(html).to have_link(t("toolbar.spending"), class: "text-taupe-400")
    end

    it "renders the accounts link as inactive" do
      expect(html).to have_link(t("toolbar.accounts"), class: "text-taupe-400")
    end
  end

  context "when on the transactions controller" do
    before do
      allow(view).to receive(:controller_path).and_return("transactions")
    end

    it "renders the spending link as active" do
      expect(html).to have_link(t("toolbar.spending"), class: "text-taupe-800")
    end

    it "renders the plan link as inactive" do
      expect(html).to have_link(t("toolbar.plan"), class: "text-taupe-400")
    end

    it "renders the accounts link as inactive" do
      expect(html).to have_link(t("toolbar.accounts"), class: "text-taupe-400")
    end
  end

  context "when on the accounts controller" do
    before do
      allow(view).to receive(:controller_path).and_return("accounts")
    end

    it "renders the accounts link as active" do
      expect(html).to have_link(t("toolbar.accounts"), class: "text-taupe-800")
    end

    it "renders the plan link as inactive" do
      expect(html).to have_link(t("toolbar.plan"), class: "text-taupe-400")
    end

    it "renders the spending link as inactive" do
      expect(html).to have_link(t("toolbar.spending"), class: "text-taupe-400")
    end
  end

  context "when on the account transactions controller" do
    before do
      allow(view).to receive(:controller_path).and_return("accounts/transactions")
    end

    it "renders the accounts link as active" do
      expect(html).to have_link(t("toolbar.accounts"), class: "text-taupe-800")
    end

    it "renders the plan link as inactive" do
      expect(html).to have_link(t("toolbar.plan"), class: "text-taupe-400")
    end

    it "renders the spending link as inactive" do
      expect(html).to have_link(t("toolbar.spending"), class: "text-taupe-400")
    end
  end
end
