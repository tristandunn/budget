# frozen_string_literal: true

require "rails_helper"

describe "Category target deletion" do
  let(:budget)      { subcategory.budget }
  let(:subcategory) { create(:category, :subcategory, :with_monthly_spending_target, name: "Groceries") }

  before do
    sign_in_for(budget)
    visit budget_path(budget)
    click_on subcategory.name
    click_on t("categories.show.target.edit")
  end

  it "deletes the target" do
    click_on t("targets.edit.delete")

    click_on subcategory.name

    expect(page).to have_link(t("categories.show.target.create"))
  end
end
