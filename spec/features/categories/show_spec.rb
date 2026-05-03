# frozen_string_literal: true

require "rails_helper"

describe "Category details" do
  let(:budget)      { subcategory.budget }
  let(:subcategory) { create(:category, :subcategory) }

  before do
    visit budget_path(budget)
    click_on subcategory.name
  end

  it "opens the category details dialog" do
    expect(page).to have_css("#category_dialog_title", text: subcategory.name)
  end

  it "links the rename button to the edit form" do
    click_on t("categories.show.rename")

    expect(page).to have_field("category_form_name", with: subcategory.name)
  end
end
