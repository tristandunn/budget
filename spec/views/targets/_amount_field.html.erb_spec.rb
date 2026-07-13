# frozen_string_literal: true

require "rails_helper"

describe "targets/_amount_field.html.erb" do
  subject(:html) do
    render partial: "targets/amount_field", locals: { form: form, placeholder: placeholder }

    rendered
  end

  let(:form)        { ActionView::Helpers::FormBuilder.new(:target_form, target_form, view, {}) }
  let(:placeholder) { t("targets.edit.amount_placeholder") }
  let(:subcategory) { build_stubbed(:category, :subcategory) }
  let(:target_form) { TargetForm.from(category: subcategory) }

  it "renders the target amount field" do
    expect(html).to have_field("target_form_target_amount_input")
  end

  it "wires the positive amount controller to the target amount field" do
    expect(html).to have_css(
      "input#target_form_target_amount_input" \
      "[data-controller='amount'][data-amount-positive-value='true']"
    )
  end

  it "renders the given placeholder" do
    expect(html).to have_field("target_form_target_amount_input", placeholder: placeholder)
  end

  it "renders a visually hidden label" do
    expect(html).to have_css("label.sr-only[for='target_form_target_amount_input']")
  end
end
