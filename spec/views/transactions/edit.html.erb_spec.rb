# frozen_string_literal: true

require "rails_helper"

describe "transactions/edit.html.erb" do
  subject(:html) do
    render template: "transactions/edit", formats: [:html]

    rendered
  end

  let(:form)        { TransactionForm.from(transaction: transaction) }
  let(:transaction) { create(:transaction) }

  before do
    stub_template("transactions/_form.html.erb" => "FORM_PARTIAL")

    assign :accounts,    transaction.budget.accounts
    assign :categories,  []
    assign :form,        form
    assign :transaction, transaction
  end

  it "renders the form partial" do
    expect(html).to include("FORM_PARTIAL")
  end
end
