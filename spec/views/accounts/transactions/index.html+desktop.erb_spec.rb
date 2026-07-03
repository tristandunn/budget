# frozen_string_literal: true

require "rails_helper"

describe "accounts/transactions/index.html+desktop.erb" do
  subject(:html) do
    render template: "accounts/transactions/index", formats: [:html], variants: [:desktop]

    rendered
  end

  let(:account) { build_stubbed(:account, budget: budget) }
  let(:budget)  { build_stubbed(:budget) }

  before do
    allow(account).to receive_messages(balance: 7_500, cleared_balance: 5_000, uncleared_balance: 2_500)

    stub_template("shared/_sidebar.html.erb"                    => "SIDEBAR_PARTIAL")
    stub_template("accounts/transactions/_actions_bar.html.erb" => "ACTIONS_BAR_PARTIAL")
    stub_template("transactions/_list.html.erb"                 => "LIST_PARTIAL")

    assign :budget,                 budget
    assign :account,                account
    assign :current_transactions,   []
    assign :scheduled_transactions, []
  end

  it "renders the sidebar" do
    expect(html).to include("SIDEBAR_PARTIAL")
  end

  it "renders the account name" do
    expect(html).to have_css("h1", text: account.name)
  end

  it "renders the account reconciled summary" do
    allow(view).to receive(:account_reconciled_summary).with(account).and_return("RECONCILED_SUMMARY")

    expect(html).to have_css("p", text: "RECONCILED_SUMMARY")
  end

  it "renders the working balance" do
    expect(html).to have_text(number_to_money(7_500))
  end

  it "renders the cleared balance" do
    expect(html).to have_css("#cleared_balance", text: number_to_money(5_000))
  end

  it "renders the uncleared balance" do
    expect(html).to have_css("#uncleared_balance", text: number_to_money(2_500))
  end

  it "renders the actions bar partial" do
    expect(html).to include("ACTIONS_BAR_PARTIAL")
  end

  it "renders the transaction list" do
    expect(html).to include("LIST_PARTIAL")
  end

  it "renders the account dialog turbo frame" do
    expect(html).to have_css("turbo-frame#account_dialog", visible: :all)
  end
end
