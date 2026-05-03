# frozen_string_literal: true

require "rails_helper"

describe "transfers/_form.html.erb" do
  subject(:html) do
    render partial: "transfers/form", locals: {
      form:   form,
      method: :post,
      url:    "/test"
    }

    rendered
  end

  let(:budget) { create(:budget) }
  let(:form)   { TransferForm.new(budget: budget) }

  it "renders the from-account picker opener with a hidden field" do
    expect(html).to have_css(
      "input[type='hidden'][name='transfer_form[from_account_id]']" \
      "[data-from-account-picker-target='hiddenField']",
      visible: :hidden
    )
  end

  it "wires the from-account opener to the picker controller" do
    expect(html).to have_css(
      "[data-action~='click->from-account-picker#open']" \
      "[data-action~='keydown->from-account-picker#openOnKey']"
    )
  end

  it "renders the to-account picker opener with a hidden field" do
    expect(html).to have_css(
      "input[type='hidden'][name='transfer_form[to_account_id]']" \
      "[data-to-account-picker-target='hiddenField']",
      visible: :hidden
    )
  end

  it "wires the to-account opener to the picker controller" do
    expect(html).to have_css(
      "[data-action~='click->to-account-picker#open']" \
      "[data-action~='keydown->to-account-picker#openOnKey']"
    )
  end

  it "configures the amount input for positive-only mode" do
    expect(html).to have_css("input[data-amount-positive-value='true']")
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

  it "renders the form with the shared transaction_form id" do
    expect(html).to have_css("form#transaction_form")
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
