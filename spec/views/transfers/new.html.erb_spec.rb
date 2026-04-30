# frozen_string_literal: true

require "rails_helper"

describe "transfers/new.html.erb" do
  subject(:html) do
    render template: "transfers/new", formats: [:html]

    rendered
  end

  let(:budget)   { build_stubbed(:budget) }
  let(:checking) { build_stubbed(:account, budget: budget, name: "Checking") }
  let(:savings)  { build_stubbed(:account, budget: budget, name: "Savings") }

  before do
    stub_template("transfers/_form.html.erb" => "FORM_PARTIAL")

    assign :accounts, [checking, savings]
    assign :budget,   budget
    assign :form,     TransferForm.new(budget: budget)
  end

  it "renders the title" do
    expect(html).to have_css("h1", text: I18n.t("transfers.new.title"))
  end

  it "renders the form partial" do
    expect(html).to include("FORM_PARTIAL")
  end
end
