# frozen_string_literal: true

require "rails_helper"

describe "transactions/_category_picker.html.erb" do
  subject(:html) do
    render partial: "transactions/category_picker", locals: {
      categories: categories,
      form:       form
    }

    rendered
  end

  let(:budget) { create(:budget) }
  let(:food)   { create(:category, budget: budget, name: "Food", position: 1) }
  let(:form)   { TransactionForm.new(budget: budget) }

  let(:subcategories) do
    [
      create(:category, :subcategory, parent: food, budget: budget, name: "Groceries", position: 1),
      create(:category, :subcategory, parent: food, budget: budget, name: "Dining",    position: 2)
    ]
  end

  let(:categories) do
    subcategories
    empty = create(:category, budget: budget, name: "Empty Parent", position: 2)

    [food, empty]
  end

  before do
    stub_template("transactions/_picker_indicator.html.erb" => "PICKER_INDICATOR_PARTIAL")
  end

  it "renders the back button" do
    expect(html).to have_button(I18n.t("transactions.picker.back"))
  end

  it "renders the search input" do
    expect(html).to have_css(
      "input[data-category-picker-target='search']" \
      "[data-action='input->category-picker#filter keydown->category-picker#selectOnKey']"
    )
  end

  it "renders a group header for parents with subcategories" do
    expect(html).to have_css("section[data-category-picker-target='group'] h3", text: food.name)
  end

  it "renders each subcategory as an item" do
    subcategories.each do |subcategory|
      expect(html).to have_css(
        "li[data-category-picker-target='item']" \
        "[data-value='#{subcategory.id}'][data-label='#{subcategory.name}']",
        text: subcategory.name
      )
    end
  end

  it "renders the picker_indicator partial inside each item" do
    subcategories.each do |subcategory|
      expect(html).to have_css(
        "li[data-category-picker-target='item'][data-value='#{subcategory.id}']",
        text: "PICKER_INDICATOR_PARTIAL"
      )
    end
  end

  it "does not render a group for parents with no subcategories" do
    expect(html).to have_no_css(
      "section[data-category-picker-target='group'] h3",
      text: "Empty Parent"
    )
  end

  context "when the form has a subcategory selected" do
    let(:form) { TransactionForm.new(budget: budget, subcategory: subcategories.first) }

    it "marks the matching item as selected" do
      expect(html).to have_css(
        "li[data-category-picker-target='item'][data-value='#{form.subcategory.id}'][aria-selected='true']"
      )
    end

    it "does not mark any other item as selected" do
      expect(html).to have_no_css(
        "li[data-category-picker-target='item']:not([data-value='#{form.subcategory.id}'])[aria-selected='true']"
      )
    end
  end

  context "when no subcategory is selected" do
    it "does not mark any item as selected" do
      expect(html).to have_no_css(
        "li[data-category-picker-target='item'][aria-selected='true']"
      )
    end
  end
end
