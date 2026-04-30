# frozen_string_literal: true

require "rails_helper"

describe "Transfer" do
  let(:budget)   { create(:budget) }
  let(:checking) { create(:account, balance: 50_000, budget: budget) }
  let(:savings)  { create(:account, balance: 20_000, budget: budget) }

  before do
    checking
    savings

    visit new_budget_transfer_path(budget)
  end

  it "creates a transfer between accounts" do
    select checking.name, from: TransferForm.human_attribute_name(:from_account)
    select savings.name,  from: TransferForm.human_attribute_name(:to_account)
    fill_in TransferForm.human_attribute_name(:amount), with: "50.00"
    click_on t("transfers.new.submit")

    expect(page)
      .to have_css("li", text: "#{t("transfers.payee.name", account: savings.name)} -$50.00")
      .and(have_css("li", text: "#{t("transfers.payee.name", account: checking.name)} $50.00"))
  end

  it "shows an inline error when the form is invalid" do
    fill_in TransferForm.human_attribute_name(:amount), with: "0"
    click_on t("transfers.new.submit")

    expect(page).to have_content(
      "#{TransferForm.human_attribute_name(:amount)} " \
      "#{t("errors.messages.greater_than", count: 0)}"
    )
  end
end
