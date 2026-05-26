# frozen_string_literal: true

require "rails_helper"

describe "Category target creation" do
  let(:budget)      { subcategory.budget }
  let(:subcategory) { create(:category, :subcategory, name: "Groceries") }

  before do
    sign_in_for(budget)
    visit budget_path(budget)
    click_on subcategory.name
    click_on t("categories.show.target.create")
  end

  it "creates a monthly spending target" do
    fill_in t("activemodel.attributes.target_form.target_amount_input"), with: "200.00"
    click_on t("targets.edit.submit")

    click_on subcategory.name

    expect(page).to have_link(t("categories.show.target.edit"))
  end
end
