# frozen_string_literal: true

require "rails_helper"

describe "accounts/transactions/_reconcile_confirmation.html.erb" do
  subject(:html) do
    render partial: "accounts/transactions/reconcile_confirmation",
           locals:  { account: account, budget: budget }

    rendered
  end

  let(:account) { build_stubbed(:account, budget: budget) }
  let(:budget)  { build_stubbed(:budget) }

  before do
    allow(account).to receive(:cleared_balance).and_return(-5000)
  end

  it "renders the prompt and cleared balance" do
    expect(html)
      .to have_text(t("accounts.transactions.reconcile.prompt"))
      .and have_text("-$50.00")
  end

  it "renders a cancel button wired to the confirm controller" do
    expect(html).to have_css(
      "button[data-action='click->confirm#cancel']",
      text: t("accounts.transactions.reconcile.decline")
    )
  end

  it "renders an accept button wired to the reconcilation path" do
    expect(html).to have_css(
      "form[action='#{budget_account_reconciliation_path(budget, account)}'] button",
      text: t("accounts.transactions.reconcile.accept")
    )
  end
end
