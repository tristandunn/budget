# frozen_string_literal: true

require "rails_helper"

describe "Category target editing" do
  let(:budget)      { subcategory.budget }
  let(:subcategory) { create(:category, :subcategory, :with_monthly_spending_target, name: "Groceries") }

  before do
    sign_in_for(budget)
    visit budget_path(budget)
    click_on subcategory.name
    click_on t("categories.show.target.edit")
  end

  it "edits the target amount" do
    fill_in t("activemodel.attributes.target_form.target_amount_input"), with: "350.00"
    click_on t("targets.edit.submit")

    click_on subcategory.name
    click_on t("categories.show.target.edit")

    expect(page).to have_field(
      t("activemodel.attributes.target_form.target_amount_input"),
      with: "350.00"
    )
  end
end
