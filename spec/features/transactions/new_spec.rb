# frozen_string_literal: true

require "rails_helper"

describe "Transaction" do
  let(:budget)      { subcategory.budget }
  let(:subcategory) { snapshot.category }

  let(:snapshot) do
    create(:category_snapshot, :for_subcategory, amount_assigned: 10_000, amount_used: 0)
  end

  before do
    visit budget_path(budget)
    click_on "add-transaction"
  end

  it "updates the amount remaining" do
    fill_in_transaction_and_submit(amount: 13.37, subcategory: subcategory)

    expect(page).to have_text("$86.63")
  end

  protected

  def fill_in_transaction_and_submit(amount:, subcategory:)
    select subcategory.name, from: t("activemodel.attributes.transaction_form.subcategory_id")
    fill_in t("activemodel.attributes.transaction_form.amount"), with: amount
    click_on t("transactions.new.submit")
  end
end
