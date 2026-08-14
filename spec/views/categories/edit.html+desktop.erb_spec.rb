# frozen_string_literal: true

require "rails_helper"

describe "categories/edit.html+desktop.erb" do
  subject(:html) do
    render template: "categories/edit", formats: [:html], variants: [:desktop]

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

  context "when anchored to a subcategory row" do
    it "renders the row rename turbo frame" do
      expect(html).to have_css("turbo-frame##{dom_id(subcategory, :rename)}")
    end

    it "renders the category name field" do
      expect(html).to have_field("category_form_name", with: subcategory.name)
    end

    it "renders a submit button" do
      expect(html).to have_button(t("categories.edit.submit"), type: "submit")
    end

    it "renders a cancel button that closes the popover" do
      expect(html).to have_css(
        "button[data-action='category-rename#close']", text: t("categories.edit.cancel")
      )
    end
  end

  context "when anchored to the sidebar panel" do
    before do
      allow(view).to receive(:params).and_return(
        ActionController::Parameters.new(panel: "true")
      )
    end

    it "renders the panel rename turbo frame" do
      expect(html).to have_css("turbo-frame##{dom_id(subcategory, :panel_rename)}")
    end

    it "renders a cancel button that closes the popover" do
      expect(html).to have_css(
        "button[data-action='category-rename#close']", text: t("categories.edit.cancel")
      )
    end

    it "submits the form preserving the panel anchor" do
      expect(html).to have_css("form[action*='panel=true']")
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
