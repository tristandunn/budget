# frozen_string_literal: true

require "rails_helper"

describe "Scheduled transactions", :js do
  let(:account) { create(:account, budget: budget) }
  let(:budget)  { create(:budget) }

  before do
    create(:transaction, :recurring, budget: budget, account: account, payee: "Future Rent")
    create(:transaction, budget: budget, account: account, payee: "Past Groceries")

    visit budget_transactions_path(budget)
  end

  it "displays the scheduled header" do
    expect(page).to have_text(t("transactions.list.scheduled"))
  end

  it "displays the recurring transaction" do
    expect(page).to have_text("Future Rent")
  end

  it "displays past transactions" do
    expect(page).to have_text("Past Groceries")
  end
end
