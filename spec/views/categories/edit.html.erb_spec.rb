# frozen_string_literal: true

require "rails_helper"

describe "categories/edit.html.erb" do
  subject(:html) do
    render template: "categories/edit", formats: [:html]

    rendered
  end

  let(:budget)      { subcategory.budget }
  let(:form)        { CategoryForm.from(category: subcategory) }
  let(:subcategory) { build_stubbed(:category, :subcategory) }

  before do
    assign :budget, budget
    assign :category, subcategory
    assign :form, form
  end

  it "renders the rename dialog turbo frame" do
    expect(html).to have_css("turbo-frame#category_rename_dialog")
  end

  it "renders the category name field" do
    expect(html).to have_field("category_form_name", with: subcategory.name)
  end

  it "renders a submit button targeting the category form" do
    expect(html).to have_css(
      "button[type='submit'][form='category_form']",
      text: t("categories.edit.submit")
    )
  end

  it "renders a cancel button that closes the dialog" do
    expect(html).to have_css(
      "button[data-action='dialog#close']", text: t("categories.edit.cancel")
    )
  end

  context "with month and year params" do
    before do
      allow(view).to receive(:params).and_return(
        ActionController::Parameters.new(year: "2025", month: "8")
      )
    end

    it "submits the form preserving the month and year" do
      expect(html).to have_css(
        "form[action='#{budget_category_path(budget, subcategory, year: "2025", month: "8")}']"
      )
    end
  end

  context "with errors" do
    before do
      form.errors.add(:name, :blank)
    end

    it "displays the name error message" do
      expect(html).to have_css(
        "p",
        normalize_ws: true,
        text:         "#{CategoryForm.human_attribute_name(:name).humanize} #{t("errors.messages.blank")}."
      )
    end
  end
end
