# frozen_string_literal: true

require "rails_helper"

describe "accounts/transactions/_actions_bar.html.erb" do
  subject(:html) do
    render partial: "accounts/transactions/actions_bar",
           locals:  { account: account, budget: budget }

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

  it "does not render the dedicated reconcile button" do
    expect(html).not_to include("RECONCILE_PARTIAL")
  end
end
