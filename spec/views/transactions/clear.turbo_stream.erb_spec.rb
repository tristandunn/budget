# frozen_string_literal: true

require "rails_helper"

describe "transactions/clear.turbo_stream.erb" do
  subject(:html) do
    render template: "transactions/clear", formats: [:turbo_stream]

    rendered
  end

  let(:context)     { nil }
  let(:transaction) { build_stubbed(:transaction, :cleared) }

  before do
    stub_template("transactions/_status_indicator.html.erb" => "STATUS_INDICATOR")

    allow(view).to receive(:params).and_return(
      ActionController::Parameters.new(context: context)
    )

    assign :transaction, transaction
  end

  it "replaces the status indicator" do
    expect(html).to have_turbo_stream_element(action: "replace", target: dom_id(transaction, :status))
  end

  it "renders the status indicator" do
    expect(html).to include("STATUS_INDICATOR")
  end

  it "replaces the cleared balance" do
    expect(html).to have_turbo_stream_element(action: "replace", target: "cleared_balance")
  end

  it "renders the cleared balance" do
    expect(html).to include(
      number_to_money(transaction.account.cleared_balance)
    )
  end

  it "replaces the uncleared balance" do
    expect(html).to have_turbo_stream_element(action: "replace", target: "uncleared_balance")
  end

  it "renders the uncleared balance" do
    expect(html).to include(
      number_to_money(transaction.account.uncleared_balance)
    )
  end

  context "when clearing from a single-account register" do
    let(:context) { "account" }

    it "does not replace the budget cleared balance" do
      expect(html).not_to have_turbo_stream_element(action: "replace", target: "budget_cleared_balance")
    end

    it "does not replace the budget uncleared balance" do
      expect(html).not_to have_turbo_stream_element(action: "replace", target: "budget_uncleared_balance")
    end
  end

  context "when clearing from the all-accounts register" do
    let(:context) { "transactions" }

    it "replaces the budget cleared balance" do
      expect(html).to have_turbo_stream_element(action: "replace", target: "budget_cleared_balance")
    end

    it "replaces the budget uncleared balance" do
      expect(html).to have_turbo_stream_element(action: "replace", target: "budget_uncleared_balance")
    end
  end
end
