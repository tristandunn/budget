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
    allow(view).to receive(:account_reconciled_summary).with(account).and_return("RECONCILED_SUMMARY")

    stub_template("shared/transactions/_hide_reconciled.html.erb" => "HIDE_RECONCILED_PARTIAL")
    stub_template("accounts/transactions/_reconcile_confirmation.html.erb" => "RECONCILE_CONFIRMATION")
  end

  it "renders a popover trigger button" do
    expect(html).to have_css(
      "button[aria-label='#{t("transactions.index.actions")}']"
    )
  end

  it "wires the popover to the confirm controller" do
    expect(html).to have_css("[data-controller='popover confirm']")
  end

  it "renders a reconcile trigger that opens the confirmation" do
    expect(html).to have_css(
      "button[data-action='click->confirm#prompt']",
      text: t("accounts.transactions.reconcile.reconcile")
    )
  end

  it "renders the reconciled summary in the reconcile trigger" do
    expect(html).to have_css(
      "button[data-action='click->confirm#prompt']",
      text: "RECONCILED_SUMMARY"
    )
  end

  it "renders the confirmation panel" do
    expect(html).to have_css("[data-confirm-target='panel']", visible: :all)
      .and include("RECONCILE_CONFIRMATION")
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

  context "when reconcile is disabled" do
    subject(:html) do
      render partial: "accounts/transactions/actions",
             locals:  { account: account, budget: budget, reconcile: false }

      rendered
    end

    it "does not render a reconcile trigger" do
      expect(html).to have_no_css("button[data-action='click->confirm#prompt']")
    end

    it "does not wire the confirm controller" do
      expect(html).to have_css("[data-controller='popover']")
        .and have_no_css("[data-controller='popover confirm']")
    end

    it "does not render the confirmation panel" do
      expect(html).to have_no_css("[data-confirm-target='panel']", visible: :all)
        .and have_no_text("RECONCILE_CONFIRMATION")
    end
  end
end
