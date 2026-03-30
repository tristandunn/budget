# frozen_string_literal: true

require "rails_helper"

describe "categories/edit.html.erb" do
  subject(:html) do
    render template: "categories/edit", formats: [:html]

    rendered
  end

  let(:budget)      { subcategory.budget }
  let(:subcategory) { create(:category, :subcategory) }

  before do
    assign :budget, budget
    assign :category, subcategory
  end

  it "renders the category name field" do
    expect(html).to have_field("category_name", with: subcategory.name)
  end

  it "renders a save button" do
    expect(html).to have_button(t("categories.edit.submit"))
  end

  context "with errors" do
    before do
      subcategory.errors.add(:name, :blank)
    end

    it "displays the name error message" do
      expect(html).to have_css("p", text: Regexp.new([
        Category.human_attribute_name(:name).humanize,
        t("errors.messages.blank")
      ].join('\s+'), Regexp::IGNORECASE))
    end
  end
end
