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
    stub_template("transactions/_payee_picker.html.erb" => "PAYEE_PICKER_PARTIAL")

    assign :accounts,    transaction.budget.accounts
    assign :categories,  []
    assign :form,        form
    assign :transaction, transaction
  end

  it "renders within a turbo frame" do
    expect(html).to have_css("turbo-frame#transaction_dialog")
  end

  it "renders the title" do
    expect(html).to have_css("h2", text: I18n.t("transactions.edit.title"))
  end

  it "renders a close button" do
    expect(html).to have_css("button[data-action='dialog#close']")
  end

  it "renders the form partial" do
    expect(html).to include("FORM_PARTIAL")
  end

  it "renders a delete button" do
    expect(html).to have_button("Delete")
  end

  it "renders the payee picker partial" do
    expect(html).to include("PAYEE_PICKER_PARTIAL")
  end
end
