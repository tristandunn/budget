# frozen_string_literal: true

require "rails_helper"

describe "accounts/transactions/_reconcile.html.erb" do
  subject(:html) do
    render partial: "accounts/transactions/reconcile",
           locals:  { account: account, budget: budget }

    rendered
  end

  let(:account) { build_stubbed(:account, budget: budget) }
  let(:budget)  { build_stubbed(:budget) }

  before do
    stub_template("accounts/transactions/_reconcile_confirmation.html.erb" => "CONFIRMATION_PARTIAL")
  end

  it "wraps the control in a confirm controller" do
    expect(html).to have_css("[data-controller='confirm']")
  end

  it "renders a reconcile trigger button" do
    expect(html).to have_button(t("accounts.transactions.reconcile.reconcile"))
  end

  it "renders the confirmation partial in a hidden panel" do
    expect(html).to have_css(
      "[data-confirm-target='panel'][hidden]",
      text:    "CONFIRMATION_PARTIAL",
      visible: :all
    )
  end
end
