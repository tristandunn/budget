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
    select checking.name, from: t("transfers.form.from_account_id")
    select savings.name,  from: t("transfers.form.to_account_id")
    fill_in t("transfers.form.amount"), with: "50.00"
    click_on t("transfers.new.submit")

    expect(page)
      .to have_css("li", text: "#{t("transfers.payee.name", account: savings.name)} -$50.00")
      .and(have_css("li", text: "#{t("transfers.payee.name", account: checking.name)} $50.00"))
  end
end
