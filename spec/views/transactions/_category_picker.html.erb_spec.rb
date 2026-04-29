# frozen_string_literal: true

require "rails_helper"

describe "transactions/_category_picker.html.erb" do
  subject(:html) do
    render partial: "transactions/category_picker", locals: { picker: picker }

    rendered
  end

  let(:amount_remaining) { 0 }
  let(:picker)           { instance_double(Transactions::CategoryPicker, groups: [group]) }
  let(:selected)         { false }

  let(:group) do
    Transactions::CategoryPicker::Group.new(
      items: [
        Transactions::CategoryPicker::Item.new(
          amount_remaining: amount_remaining,
          id:               1,
          name:             "Groceries",
          selected:         selected
        )
      ],
      name:  "Food"
    )
  end

  it "renders the search input" do
    expect(html).to have_css(
      "input[data-category-picker-target='search']" \
      "[data-action='input->category-picker#filter keydown->category-picker#selectOnKey']"
    )
  end

  it "renders a group header" do
    expect(html).to have_css("section[data-category-picker-target='group'] h3", text: "Food")
  end

  it "renders each item" do
    expect(html).to have_css(
      "li[data-category-picker-target='item'][data-value='1'][data-label='Groceries']",
      text: "Groceries"
    )
  end

  context "with a positive amount remaining" do
    let(:amount_remaining) { 7_500 }

    it "renders the amount in bold green" do
      expect(html).to have_css("li[data-value='1'] span.font-bold.text-green-600", text: "$75.00")
    end
  end

  context "with a zero amount remaining" do
    let(:amount_remaining) { 0 }

    it "renders the amount in bold grey" do
      expect(html).to have_css("li[data-value='1'] span.font-bold.text-gray-400", text: "$0.00")
    end
  end

  context "with a negative amount remaining" do
    let(:amount_remaining) { -1_500 }

    it "renders the amount in bold dark gray" do
      expect(html).to have_css("li[data-value='1'] span.font-bold.text-gray-900", text: "-$15.00")
    end
  end

  context "when the item is selected" do
    let(:selected) { true }

    it "marks the item as selected" do
      expect(html).to have_css("li[data-category-picker-target='item'][data-value='1'][aria-selected='true']")
    end
  end

  context "when the item is not selected" do
    it "does not mark the item as selected" do
      expect(html).to have_no_css("li[data-category-picker-target='item'][aria-selected='true']")
    end
  end
end
