# frozen_string_literal: true

require "rails_helper"

describe "accounts/transactions/_actions_bar.html+desktop.erb" do
  subject(:html) do
    render partial:  "accounts/transactions/actions_bar",
           variants: [:desktop],
           locals:   { account: account, budget: budget }

    rendered
  end

  let(:account) { build_stubbed(:account, budget: budget) }
  let(:budget)  { build_stubbed(:budget) }

  before do
    stub_template("accounts/transactions/_actions.html.erb"   => "ACTIONS_PARTIAL")
    stub_template("accounts/transactions/_reconcile.html.erb" => "RECONCILE_PARTIAL")
  end

  it "renders the actions in an identified container" do
    expect(html).to have_css("#account_actions", text: "ACTIONS_PARTIAL")
  end

  context "when the account is reconcilable" do
    before do
      allow(account).to receive(:reconcilable?).and_return(true)
    end

    it "renders the dedicated reconcile button" do
      expect(html).to include("RECONCILE_PARTIAL")
    end
  end

  context "when the account is not reconcilable" do
    before do
      allow(account).to receive(:reconcilable?).and_return(false)
    end

    it "does not render the dedicated reconcile button" do
      expect(html).not_to include("RECONCILE_PARTIAL")
    end
  end
end
