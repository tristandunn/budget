# frozen_string_literal: true

require "rails_helper"

describe "Category target unsnoozing", :mobile do
  let(:budget)      { subcategory.budget }
  let(:subcategory) do
    create(:category, :subcategory, :with_monthly_spending_target, name: "Groceries", with_snapshot: false)
  end

  before do
    create(:category_snapshot,
           budget:   budget,
           category: subcategory,
           date:     Date.current.beginning_of_month,
           metadata: { "snoozed" => true })

    sign_in_for(budget)
    visit budget_path(budget)
    click_on subcategory.name
  end

  it "unsnoozes the target for the displayed month" do
    click_on t("categories.show.target.unsnooze")

    click_on subcategory.name

    expect(page).to have_button(t("categories.show.target.snooze"))
  end
end
