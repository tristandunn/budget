# frozen_string_literal: true

require "rails_helper"

describe "Category editing" do
  let(:budget)      { subcategory.budget }
  let(:subcategory) { create(:category, :subcategory) }

  before do
    visit budget_path(budget)
    click_on subcategory.name
    click_on t("categories.show.rename")
  end

  it "updates the category name" do
    fill_in "category_form_name", with: "New Name"
    click_on t("categories.edit.submit")

    expect(page).to have_text("New Name")
  end
end
