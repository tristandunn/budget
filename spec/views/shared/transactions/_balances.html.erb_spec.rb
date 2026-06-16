# frozen_string_literal: true

require "rails_helper"

describe "shared/transactions/_balances.html.erb" do
  subject(:html) do
    render partial: "shared/transactions/balances", locals: locals

    rendered
  end

  let(:locals) { { record: record } }
  let(:record) do
    instance_double(Account, balance: 7_500, cleared_balance: 5_000, uncleared_balance: 2_500)
  end

  it "renders the cleared balance" do
    expect(html).to have_css("#cleared_balance", text: number_to_money(5_000))
  end

  it "renders the cleared label" do
    expect(html).to have_text(t("transactions.balances.cleared"))
  end

  it "renders the uncleared balance" do
    expect(html).to have_css("#uncleared_balance", text: number_to_money(2_500))
  end

  it "renders the uncleared label" do
    expect(html).to have_text(t("transactions.balances.uncleared"))
  end

  it "renders the working balance" do
    expect(html).to have_text(number_to_money(7_500))
  end

  it "renders the working label" do
    expect(html).to have_text(t("transactions.balances.working"))
  end

  context "when given a prefix" do
    let(:locals) { { record: record, prefix: "budget_" } }

    it "prefixes the cleared balance id" do
      expect(html).to have_css("#budget_cleared_balance")
    end

    it "prefixes the uncleared balance id" do
      expect(html).to have_css("#budget_uncleared_balance")
    end
  end
end
