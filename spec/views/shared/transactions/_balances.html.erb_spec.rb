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

  it "does not render the selected total" do
    expect(html).to have_no_css("[data-transaction-selection-target='total']", visible: :all)
  end

  it "styles the balances container with the default classes" do
    expect(html).to have_css("div.border-y.border-taupe-300.px-6:has(#cleared_balance)")
  end

  context "when given a container class" do
    let(:locals) { { record: record, container_class: "border-taupe-200 px-4" } }

    it "styles the balances container with the given classes" do
      expect(html).to have_css("div.border-y.border-taupe-200.px-4:has(#cleared_balance)")
    end

    it "does not retain the default styling" do
      expect(html).to have_no_css("div.border-taupe-300:has(#cleared_balance)")
        .and(have_no_css("div.px-6:has(#cleared_balance)"))
    end
  end

  context "when selectable" do
    let(:locals) { { record: record, selectable: true } }

    it "renders an empty selected total frame hidden until a selection is made" do
      expect(html).to have_css(
        "turbo-frame#transaction_selection[hidden][data-transaction-selection-target='total']",
        text:    "",
        visible: :all
      )
    end

    it "aligns the selected total to the right" do
      expect(html).to have_css(
        "turbo-frame#transaction_selection.ml-auto.text-right",
        visible: :all
      )
    end
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
