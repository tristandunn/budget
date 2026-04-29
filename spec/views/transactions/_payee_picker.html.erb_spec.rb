# frozen_string_literal: true

require "rails_helper"

describe "transactions/_payee_picker.html.erb" do
  subject(:html) do
    render partial: "transactions/payee_picker", locals: { form: form, payees: payees }

    rendered
  end

  let(:budget) { create(:budget) }
  let(:form)   { TransactionForm.new(budget: budget) }

  let(:payees) do
    [
      create(:payee, budget: budget, name: "Alpha"),
      create(:payee, budget: budget, name: "Beta")
    ]
  end

  it "renders the search input" do
    expect(html).to have_css(
      "input[data-payee-picker-target='search']" \
      "[data-action='input->payee-picker#filter keydown->payee-picker#selectOnKey']"
    )
  end

  it "renders each payee as an item" do
    payees.each do |payee|
      expect(html).to have_css(
        "li[data-payee-picker-target='item'][data-value='#{payee.name}'][data-label='#{payee.name}']",
        text: payee.name
      )
    end
  end

  it "renders the create payee template" do
    expect(html).to have_css(
      "template[data-payee-picker-target='createPayeeTemplate']",
      visible: :all
    )
  end

  context "when the form has a payee selected" do
    let(:form) { TransactionForm.new(budget: budget, payee: payees.first.name) }

    it "marks the matching item as selected" do
      expect(html).to have_css(
        "li[data-payee-picker-target='item'][data-value='#{form.payee}'][aria-selected='true']"
      )
    end

    it "does not mark any other item as selected" do
      expect(html).to have_no_css(
        "li[data-payee-picker-target='item']:not([data-value='#{form.payee}'])[aria-selected='true']"
      )
    end
  end
end
