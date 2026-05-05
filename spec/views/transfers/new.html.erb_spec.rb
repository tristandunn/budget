# frozen_string_literal: true

require "rails_helper"

describe "transfers/new.html.erb" do
  subject(:html) do
    render template: "transfers/new", formats: [:html]

    rendered
  end

  let(:budget)      { build_stubbed(:budget) }
  let(:checking)    { build_stubbed(:account, budget: budget, name: "Checking") }
  let(:credit_card) { build_stubbed(:account, :credit, budget: budget, name: "Credit Card") }

  before do
    stub_template("transfers/_form.html.erb" => "FORM_PARTIAL")

    assign :accounts, [checking, credit_card]
    assign :budget,   budget
    assign :form,     TransferForm.new(budget: budget)
  end

  it "renders the title" do
    expect(html).to have_css("h2", text: t("transfers.new.title"))
  end

  it "renders inside the transaction dialog turbo frame" do
    expect(html).to have_css("turbo-frame#transaction_dialog")
  end

  it "renders a cancel button" do
    expect(html).to have_css(
      "button[data-action='dialog#close']",
      text: t("transfers.new.cancel")
    )
  end

  it "renders a submit button targeting the transaction form" do
    expect(html).to have_css(
      "button[type='submit'][form='transaction_form']",
      text: t("transfers.new.submit")
    )
  end

  it "renders the form partial" do
    expect(html).to include("FORM_PARTIAL")
  end
end
