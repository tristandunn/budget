# frozen_string_literal: true

require "rails_helper"

describe "payees/edit.html.erb" do
  subject(:html) do
    render template: "payees/edit", formats: [:html]

    rendered
  end

  let(:budget) { payee.budget }
  let(:form)   { PayeeForm.from(payee: payee) }
  let(:payee)  { build_stubbed(:payee) }

  before do
    assign :budget, budget
    assign :payee,  payee
    assign :form,   form
  end

  it "renders the rename dialog turbo frame" do
    expect(html).to have_css("turbo-frame#payee_rename_dialog")
  end

  it "renders the payee name field with the current name" do
    expect(html).to have_field("payee_form_name", with: payee.name)
  end

  it "renders a submit button targeting the payee form" do
    expect(html).to have_css(
      "button[type='submit'][form='payee_form']",
      text: t("payees.edit.submit")
    )
  end

  it "renders a cancel button that closes the dialog" do
    expect(html).to have_css(
      "button[data-action='dialog#close']", text: t("payees.edit.cancel")
    )
  end

  it "submits the form to the payee path" do
    expect(html).to have_css("form[action='#{budget_payee_path(budget, payee)}']")
  end

  context "with errors" do
    before do
      form.errors.add(:name, :blank)
    end

    it "displays the name error message" do
      expect(html).to have_css(
        "p",
        normalize_ws: true,
        text:         "#{PayeeForm.human_attribute_name(:name).humanize} #{t("errors.messages.blank")}."
      )
    end
  end
end
