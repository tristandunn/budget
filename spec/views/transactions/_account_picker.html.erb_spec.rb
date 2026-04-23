# frozen_string_literal: true

require "rails_helper"

describe "transactions/_account_picker.html.erb" do
  subject(:html) do
    render partial: "transactions/account_picker", locals: {
      accounts: accounts,
      form:     form
    }

    rendered
  end

  let(:accounts) do
    [
      create(:account, budget: budget, name: "Checking"),
      create(:account, :credit, budget: budget, name: "Visa")
    ]
  end

  let(:budget) { create(:budget) }
  let(:form)   { TransactionForm.new(budget: budget) }

  before do
    stub_template("transactions/_picker_indicator.html.erb" => "PICKER_INDICATOR_PARTIAL")
  end

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

  it "renders the picker_indicator partial inside each item" do
    accounts.each do |account|
      expect(html).to have_css(
        "li[data-account-picker-target='item'][data-value='#{account.id}']",
        text: "PICKER_INDICATOR_PARTIAL"
      )
    end
  end

  context "without any credit accounts" do
    let(:accounts) { [create(:account, budget: budget, name: "Checking")] }

    it "does not render the credit group" do
      expect(html).to have_no_css(
        "section[data-account-picker-target='group'] h3",
        text: t("accounts.index.credit")
      )
    end
  end

  context "without any cash accounts" do
    let(:accounts) { [create(:account, :credit, budget: budget, name: "Visa")] }

    it "does not render the cash group" do
      expect(html).to have_no_css(
        "section[data-account-picker-target='group'] h3",
        text: t("accounts.index.cash")
      )
    end
  end

  context "when the form has an account selected" do
    let(:form) { TransactionForm.new(budget: budget, account: accounts.first) }

    it "marks the matching item as selected" do
      expect(html).to have_css(
        "li[data-account-picker-target='item'][data-value='#{form.account.id}'][aria-selected='true']"
      )
    end

    it "does not mark any other item as selected" do
      expect(html).to have_no_css(
        "li[data-account-picker-target='item']:not([data-value='#{form.account.id}'])[aria-selected='true']"
      )
    end
  end
end
