# frozen_string_literal: true

require "rails_helper"

describe "accounts/_picker.html.erb" do
  subject(:html) do
    render partial: "accounts/picker", locals: {
      accounts:   accounts,
      controller: picker_name,
      selected:   selected
    }

    rendered
  end

  let(:accounts) do
    [
      build_stubbed(:account, budget: budget, name: "Checking"),
      build_stubbed(:account, :credit, budget: budget, name: "Visa")
    ]
  end

  let(:budget)      { build_stubbed(:budget) }
  let(:picker_name) { "account-picker" }
  let(:selected)    { nil }

  it "does not render a search input" do
    expect(html).to have_no_css("input[data-account-picker-target='search']")
  end

  it "renders the cash and credit group headers" do
    expect(html).to have_css("section[data-account-picker-target='group'] h3", text: t("accounts.index.cash"))
      .and have_css("section[data-account-picker-target='group'] h3", text: t("accounts.index.credit"))
  end

  it "renders each account as an item" do
    accounts.each do |account|
      expect(html).to have_css(
        "li[data-account-picker-target='item']" \
        "[data-value='#{account.id}'][data-label='#{account.name}']",
        text: account.name
      )
    end
  end

  it "wires each item to the controller's select action" do
    expect(html).to have_css(
      "li[data-account-picker-target='item'][data-action='click->account-picker#select']",
      count: accounts.size
    )
  end

  context "when an account is selected" do
    let(:selected) { accounts.first }

    it "marks the matching item as selected" do
      expect(html).to have_css(
        "li[data-account-picker-target='item'][data-value='#{selected.id}'][aria-selected='true']"
      )
    end

    it "does not mark any other item as selected" do
      expect(html).to have_no_css(
        "li[data-account-picker-target='item']:not([data-value='#{selected.id}'])[aria-selected='true']"
      )
    end
  end

  context "with the from-account-picker controller" do
    let(:picker_name) { "from-account-picker" }

    it "emits items with the from-account-picker target" do
      expect(html).to have_css(
        "li[data-from-account-picker-target='item']",
        count: accounts.size
      )
    end

    it "tags groups with the from-account-picker target" do
      expect(html).to have_css("section[data-from-account-picker-target='group']", count: 2)
    end

    it "wires items to the from-account-picker select action" do
      expect(html).to have_css(
        "li[data-from-account-picker-target='item'][data-action='click->from-account-picker#select']",
        count: accounts.size
      )
    end
  end

  context "with the to-account-picker controller" do
    let(:picker_name) { "to-account-picker" }

    it "emits items with the to-account-picker target" do
      expect(html).to have_css(
        "li[data-to-account-picker-target='item']",
        count: accounts.size
      )
    end

    it "tags groups with the to-account-picker target" do
      expect(html).to have_css("section[data-to-account-picker-target='group']", count: 2)
    end

    it "wires items to the to-account-picker select action" do
      expect(html).to have_css(
        "li[data-to-account-picker-target='item'][data-action='click->to-account-picker#select']",
        count: accounts.size
      )
    end
  end

  context "without any cash accounts" do
    let(:accounts) { [build_stubbed(:account, :credit, budget: budget, name: "Visa")] }

    it "does not render the cash group" do
      expect(html).to have_no_css(
        "section[data-account-picker-target='group'] h3",
        text: t("accounts.index.cash")
      )
    end
  end

  context "without any credit accounts" do
    let(:accounts) { [build_stubbed(:account, budget: budget, name: "Checking")] }

    it "does not render the credit group" do
      expect(html).to have_no_css(
        "section[data-account-picker-target='group'] h3",
        text: t("accounts.index.credit")
      )
    end
  end
end
