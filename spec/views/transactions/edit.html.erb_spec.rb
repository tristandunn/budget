# frozen_string_literal: true

require "rails_helper"

describe "transactions/edit.html.erb" do
  subject(:html) do
    render template: "transactions/edit", formats: [:html]

    rendered
  end

  let(:form)        { TransactionForm.from(transaction: transaction) }
  let(:transaction) { build_stubbed(:transaction) }

  before do
    stub_template("transactions/_form.html.erb" => "FORM_PARTIAL")
    stub_template("transactions/_transfer_details.html.erb" => "TRANSFER_DETAILS_PARTIAL")
    stub_template("transactions/_payee_picker.html.erb" => "PAYEE_PICKER_PARTIAL")
    stub_template("transactions/_category_picker.html.erb" => "CATEGORY_PICKER_PARTIAL")
    stub_template("accounts/_picker.html.erb" => "ACCOUNT_PICKER_PARTIAL")

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

  it "renders the category picker partial" do
    expect(html).to include("CATEGORY_PICKER_PARTIAL")
  end

  it "renders the account picker partial" do
    expect(html).to include("ACCOUNT_PICKER_PARTIAL")
  end

  context "when the transaction is a transfer" do
    let(:transaction) { build_stubbed(:transaction, transfer_pair_id: 1) }

    it "renders the transfer details partial" do
      expect(html).to include("TRANSFER_DETAILS_PARTIAL")
    end

    it "does not render the form partial" do
      expect(html).not_to include("FORM_PARTIAL")
    end

    it "does not render a delete button" do
      expect(html).to have_no_button("Delete")
    end
  end
end
