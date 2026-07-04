# frozen_string_literal: true

require "rails_helper"

describe "Category target snoozing", :mobile do
  let(:budget)      { subcategory.budget }
  let(:subcategory) { create(:category, :subcategory, :with_monthly_spending_target, name: "Groceries") }

  before do
    sign_in_for(budget)
    visit budget_path(budget)
    click_on subcategory.name
  end

  it "snoozes the target for the displayed month" do
    click_on t("categories.show.target.snooze")

    click_on subcategory.name

    expect(page).to have_button(t("categories.show.target.unsnooze"))
  end
end
