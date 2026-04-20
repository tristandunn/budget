# frozen_string_literal: true

require "rails_helper"

describe "transactions/_payee_picker.html.erb" do
  subject(:html) do
    render partial: "transactions/payee_picker"

    rendered
  end

  it "renders the back button" do
    expect(html).to have_button(I18n.t("transactions.picker.back"))
  end

  it "renders the search input" do
    expect(html).to have_css(
      "input[data-payee-picker-target='search']" \
      "[data-action='input->payee-picker#filter keydown->payee-picker#selectOnKey']"
    )
  end

  it "renders the payee list" do
    expect(html).to have_css("[data-payee-picker-target='list']")
  end

  it "renders the create payee template" do
    expect(html).to have_css(
      "template[data-payee-picker-target='createPayeeTemplate']",
      visible: :all
    )
  end
end
