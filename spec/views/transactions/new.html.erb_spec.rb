# frozen_string_literal: true

require "rails_helper"

describe "transactions/new.html.erb" do
  subject(:html) do
    render template: "transactions/new", formats: [:html]

    rendered
  end

  let(:accounts)      { budget.accounts }
  let(:budget)        { subcategory.budget }
  let(:form)          { TransactionForm.new(budget: budget, subcategory: subcategory) }
  let(:subcategories) { budget.subcategories }
  let(:subcategory)   { create(:category, :subcategory) }

  before do
    assign :accounts, accounts
    assign :form, form
    assign :subcategories, subcategories
  end

  it "renders the amount field" do
    expect(html).to have_field("transaction_form_amount")
  end

  it "renders the payee field" do
    expect(html).to have_field("transaction_form_payee")
  end

  it "renders the subcategory select" do
    expect(html).to have_select("transaction_form_subcategory_id")
  end

  it "renders the account select" do
    expect(html).to have_select("transaction_form_account_id")
  end

  it "renders the date field" do
    expect(html).to have_field("transaction_form_date")
  end

  it "renders the memo field" do
    expect(html).to have_field("transaction_form_memo")
  end

  it "renders the submit button" do
    expect(html).to have_button(I18n.t("transactions.new.submit"))
  end

  context "with errors" do
    let(:form) do
      TransactionForm.new(amount: "12.50", budget: budget, payee: "Test Payee", subcategory: subcategory)
    end

    before do
      form.errors.add(:amount, :blank)
      form.errors.add(:date, :blank)
      form.errors.add(:payee, :blank)
      form.errors.add(:subcategory, :blank)
    end

    it "preserves the entered amount" do
      expect(html).to have_field("transaction_form_amount", with: "12.50")
    end

    it "preserves the entered payee" do
      expect(html).to have_field("transaction_form_payee", with: "Test Payee")
    end

    it "wraps amount field in error container" do
      expect(html).to have_css(".field_with_errors #transaction_form_amount")
    end

    it "displays amount error message" do
      expect(html).to have_css("p", text: Regexp.new([
        TransactionForm.human_attribute_name(:amount).humanize,
        t("errors.messages.blank")
      ].join('\s+'), Regexp::IGNORECASE))
    end

    it "displays subcategory error message" do
      expect(html).to have_css("p", text: Regexp.new([
        TransactionForm.human_attribute_name(:subcategory_id).humanize,
        t("errors.messages.blank")
      ].join('\s+'), Regexp::IGNORECASE))
    end

    it "displays payee error message" do
      expect(html).to have_css("p", text: Regexp.new([
        TransactionForm.human_attribute_name(:payee).humanize,
        t("errors.messages.blank")
      ].join('\s+'), Regexp::IGNORECASE))
    end

    it "displays date error message" do
      expect(html).to have_css("p", text: Regexp.new([
        TransactionForm.human_attribute_name(:date).humanize,
        t("errors.messages.blank")
      ].join('\s+'), Regexp::IGNORECASE))
    end
  end
end
