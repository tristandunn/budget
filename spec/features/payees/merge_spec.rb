# frozen_string_literal: true

require "rails_helper"

describe "Merging a payee" do
  let(:account)       { create(:account, budget: budget) }
  let(:budget)        { create(:budget) }
  let!(:source_payee) { create(:payee, budget: budget) }
  let!(:target_payee) { create(:payee, budget: budget) }

  before do
    create(:transaction, budget: budget, account: account, payee: source_payee, amount: -1_000)
    create(:transaction, budget: budget, account: account, payee: source_payee, amount: -2_000)

    sign_in_for(budget)
    visit budget_payees_path(budget)
    click_on source_payee.name
    fill_in "payee_form_name", with: target_payee.name
    click_on t("payees.edit.submit")
  end

  it "removes the renamed payee from the list" do
    expect(page).to have_text(target_payee.name).and(have_no_text(source_payee.name))
  end

  it "reassigns the renamed payee's transactions" do
    visit budget_transactions_path(budget)

    expect(page).to have_css("tr", text: target_payee.name, count: 2)
      .and(have_css("tr", text: "$10.00"))
      .and(have_css("tr", text: "$20.00"))
      .and(have_no_text(source_payee.name))
  end
end
