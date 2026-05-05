# frozen_string_literal: true

require "rails_helper"

describe "accounts/transactions/_actions.html.erb" do
  subject(:html) do
    render partial: "accounts/transactions/actions",
           locals:  { account: account, budget: budget }

    rendered
  end

  let(:account) { build_stubbed(:account, budget: budget) }
  let(:budget)  { build_stubbed(:budget) }

  before do
    stub_template("shared/transactions/_hide_reconciled.html.erb" => "HIDE_RECONCILED_PARTIAL")
  end

  it "renders a popover trigger button" do
    expect(html).to have_css(
      "button[aria-label='#{t("transactions.index.actions")}']"
    )
  end

  it "renders a reconcile button" do
    expect(html).to have_button(t("accounts.transactions.actions.reconcile"))
  end

  it "renders a confirmation dialog" do
    expect(html).to have_css("[data-turbo-confirm]")
  end

  it "renders the hide reconciled partial" do
    expect(html).to include("HIDE_RECONCILED_PARTIAL")
  end

  it "renders an edit account link targeting the account dialog" do
    expect(html).to have_link(t("accounts.transactions.actions.edit"),
                              href: edit_budget_account_path(budget, account))
  end

  it "wires the edit link to the account dialog turbo frame" do
    expect(html).to have_css(
      "a[href='#{edit_budget_account_path(budget, account)}'][data-turbo-frame='account_dialog']"
    )
  end

  context "when the account is a credit account" do
    let(:account) { build_stubbed(:account, :credit, budget: budget) }

    it "renders a record payment link targeting the transaction dialog" do
      expect(html).to have_link(
        t("accounts.transactions.actions.record_payment"),
        href: new_budget_transfer_path(budget, to_account_id: account.id)
      )
    end
  end

  context "when the account is not a credit account" do
    it "does not render a record payment link" do
      expect(html).to have_no_link(t("accounts.transactions.actions.record_payment"))
    end
  end

  context "when the account has been reconciled" do
    let(:account) { create(:account, budget: budget) }
    let(:budget)  { create(:budget) }

    before do
      create(:transaction, account: account, status: :reconciled)
    end

    it "renders the last reconciled time" do
      expect(html).to have_text("Reconciled today")
    end
  end

  context "when the account has never been reconciled" do
    it "renders reconciled never" do
      expect(html).to have_text(t("accounts.transactions.actions.reconciled_never"))
    end
  end
end
