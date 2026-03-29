# frozen_string_literal: true

require "rails_helper"

describe "transactions/new.html.erb" do
  subject(:html) do
    render template: "transactions/new", formats: [:html]

    rendered
  end

  let(:budget) { create(:budget) }
  let(:form)   { TransactionForm.new(budget: budget) }

  before do
    stub_template("transactions/_form.html.erb" => "FORM_PARTIAL")

    assign :accounts,   budget.accounts
    assign :categories, []
    assign :form,       form
  end

  it "renders the form partial" do
    expect(html).to include("FORM_PARTIAL")
  end
end
