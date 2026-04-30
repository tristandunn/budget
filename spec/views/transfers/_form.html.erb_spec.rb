# frozen_string_literal: true

require "rails_helper"

describe "transfers/_form.html.erb" do
  subject(:html) do
    render partial: "transfers/form", locals: {
      accounts:     accounts,
      form:         form,
      method:       :post,
      submit_label: "Transfer",
      url:          "/test"
    }

    rendered
  end

  let(:accounts) { [checking, savings] }
  let(:budget)   { create(:budget) }
  let(:checking) { create(:account, budget: budget) }
  let(:form)     { TransferForm.new(budget: budget) }
  let(:savings)  { create(:account, budget: budget) }

  it "renders the from-account select with each account as an option" do
    expect(html).to have_select("transfer_form_from_account_id", options: [checking.name, savings.name])
  end

  it "renders the to-account select with each account as an option" do
    expect(html).to have_select("transfer_form_to_account_id", options: [checking.name, savings.name])
  end

  it "renders the amount field" do
    expect(html).to have_field("transfer_form_amount")
  end

  it "renders the date field" do
    expect(html).to have_field("transfer_form_date")
  end

  it "renders the memo field" do
    expect(html).to have_field("transfer_form_memo")
  end

  it "renders the submit button with the provided label" do
    expect(html).to have_button("Transfer")
  end

  context "with an amount greater_than error" do
    before do
      form.errors.add(:amount, :greater_than, count: 0)
    end

    it "displays the amount error message" do
      expect(html).to have_css(
        "p",
        normalize_ws: true,
        text:         "#{TransferForm.human_attribute_name(:amount)} " \
                      "#{t("errors.messages.greater_than", count: 0)}."
      )
    end
  end

  context "with a from_account presence error" do
    before do
      form.errors.add(:from_account, :blank)
    end

    it "displays the from-account error message" do
      expect(html).to have_css(
        "p",
        normalize_ws: true,
        text:         "#{TransferForm.human_attribute_name(:from_account)} #{t("errors.messages.blank")}."
      )
    end
  end

  context "with a to_account must-not-match error" do
    before do
      form.errors.add(:to_account, :must_not_match_source)
    end

    it "displays the must-not-match message" do
      expect(html).to have_css(
        "p",
        normalize_ws: true,
        text:         "#{TransferForm.human_attribute_name(:to_account)} " \
                      "#{t("activemodel.errors.models.transfer_form.attributes.to_account.must_not_match_source")}."
      )
    end
  end
end
