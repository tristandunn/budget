# frozen_string_literal: true

require "rails_helper"

describe "transactions/clear.turbo_stream.erb" do
  subject(:html) do
    render template: "transactions/clear", formats: [:turbo_stream]

    rendered
  end

  let(:transaction) { create(:transaction, :cleared) }

  before do
    stub_template("transactions/_status_indicator.html.erb" => "STATUS_INDICATOR")

    assign :transaction, transaction
  end

  it "replaces the status indicator" do
    expect(html).to have_css(
      "turbo-stream[action='replace'][target='#{dom_id(transaction, :status)}']"
    )
  end

  it "renders the status indicator" do
    expect(html).to include("STATUS_INDICATOR")
  end

  it "replaces the cleared balance" do
    expect(html).to have_css("turbo-stream[action='replace'][target='cleared_balance']")
  end

  it "renders the cleared balance" do
    expect(html).to include(
      number_to_currency(Money.from_cents(transaction.account.cleared_balance))
    )
  end

  it "replaces the uncleared balance" do
    expect(html).to have_css("turbo-stream[action='replace'][target='uncleared_balance']")
  end

  it "renders the uncleared balance" do
    expect(html).to include(
      number_to_currency(Money.from_cents(transaction.account.uncleared_balance))
    )
  end
end
