# frozen_string_literal: true

require "rails_helper"

describe "transactions/index.html+desktop.erb" do
  subject(:html) do
    render template: "transactions/index", formats: [:html], variants: [:desktop]

    rendered
  end

  let(:budget) { build_stubbed(:budget) }

  before do
    allow(budget).to receive_messages(balance: 7_500, cleared_balance: 5_000, uncleared_balance: 2_500)

    stub_template("shared/_sidebar.html.erb"        => "SIDEBAR_PARTIAL")
    stub_template("transactions/_actions.html.erb"  => "ACTIONS_PARTIAL")
    stub_template("transactions/_list.html.erb"     => "LIST_PARTIAL")

    assign :budget,                 budget
    assign :current_transactions,   []
    assign :scheduled_transactions, []
  end

  it "renders the sidebar" do
    expect(html).to include("SIDEBAR_PARTIAL")
  end

  it "renders the all accounts header" do
    expect(html).to have_css("h1", text: t("sidebar.all_accounts"))
  end

  it "renders the budget cleared balance" do
    expect(html).to have_css("#budget_cleared_balance", text: number_to_money(5_000))
  end

  it "renders the budget uncleared balance" do
    expect(html).to have_css("#budget_uncleared_balance", text: number_to_money(2_500))
  end

  it "renders the budget working balance" do
    expect(html).to have_text(number_to_money(7_500))
  end

  it "renders the actions partial" do
    expect(html).to include("ACTIONS_PARTIAL")
  end

  it "renders the transaction list" do
    expect(html).to include("LIST_PARTIAL")
  end
end
