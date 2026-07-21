# frozen_string_literal: true

require "rails_helper"

describe "budgets/edit.html+desktop.erb" do
  subject(:html) do
    render template: "budgets/edit", formats: [:html], variants: [:desktop]

    rendered
  end

  let(:budget) { build_stubbed(:budget) }

  before do
    assign :budget, budget
  end

  it "renders the settings dialog turbo frame" do
    expect(html).to have_css("turbo-frame#budget_settings_dialog")
  end

  it "renders the settings title" do
    expect(html).to have_css("#budget_settings_dialog_title", text: t("budgets.edit.title"))
  end

  it "renders a close button bound to the dialog controller" do
    expect(html).to have_css(
      "button[data-action='dialog#close'][aria-label='#{t("budgets.edit.close")}']"
    )
  end

  it "submits the form as a PATCH to the budget path" do
    expect(html).to have_css(
      "form[action='#{budget_path(budget)}'] input[name='_method'][value='patch']",
      visible: :hidden
    )
  end

  it "renders the name field with the current name" do
    expect(html).to have_field("budget_name", with: budget.name)
  end

  it "limits the name field to the maximum length and requires it" do
    expect(html).to have_css(
      "input#budget_name[required][maxlength='#{Budget::MAXIMUM_NAME_LENGTH}']"
    )
  end

  it "renders the cancel button bound to the dialog controller" do
    expect(html).to have_css("button[data-action='dialog#close']", text: t("budgets.edit.cancel"))
  end

  it "renders the submit button" do
    expect(html).to have_button(t("budgets.edit.submit"))
  end

  it "does not render an error message" do
    expect(html).to have_no_css("[role='alert']")
  end

  context "when the name is invalid" do
    before do
      budget.errors.add(:name, :blank)
    end

    it "renders the validation error message" do
      expect(html).to have_css(
        "[role='alert']",
        text: "#{Budget.human_attribute_name(:name)} #{t("errors.messages.blank")}."
      )
    end
  end
end
