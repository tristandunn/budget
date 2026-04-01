# frozen_string_literal: true

require "rails_helper"

describe "transactions/_form.html.erb" do
  subject(:html) do
    render partial: "transactions/form", locals: {
      accounts:     accounts,
      categories:   categories,
      form:         form,
      method:       :post,
      submit_label: "Save",
      url:          "/test"
    }

    rendered
  end

  let(:accounts)    { subcategory.budget.accounts }
  let(:categories)  { subcategory.budget.categories.reject(&:inflow?).sort_by(&:position) }
  let(:form)        { TransactionForm.new(budget: subcategory.budget, subcategory: subcategory) }
  let(:subcategory) { create(:category, :subcategory) }

  it "renders the amount field" do
    expect(html).to have_field("transaction_form_amount")
  end

  it "renders the payee field" do
    expect(html).to have_field("transaction_form_payee")
  end

  it "renders the subcategory select" do
    expect(html).to have_select("transaction_form_subcategory_id")
  end

  it "groups subcategories under their parent category" do
    parent = subcategory.parent

    expect(html).to have_css("optgroup[label='#{parent.name}'] option", text: subcategory.name)
  end

  it "does not include inflow categories" do
    inflow = create(:category, :inflow, budget: subcategory.budget)

    expect(html).to have_no_css("optgroup[label='#{inflow.name}']")
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

  it "renders the submit button with the provided label" do
    expect(html).to have_button("Save")
  end

  context "when prepopulated from a transaction" do
    let(:form)        { TransactionForm.from(transaction: transaction) }
    let(:transaction) { create(:transaction, budget: subcategory.budget, memo: "Memo", subcategory: subcategory) }

    it "prepopulates the amount" do
      expect(html).to have_field("transaction_form_amount",
                                 with: Money.from_cents(transaction.amount).to_s)
    end

    it "prepopulates the payee" do
      expect(html).to have_field("transaction_form_payee", with: transaction.payee)
    end

    it "prepopulates the date" do
      expect(html).to have_field("transaction_form_date", with: transaction.date.to_s)
    end

    it "prepopulates the memo" do
      expect(html).to have_field("transaction_form_memo", with: transaction.memo)
    end

    it "preselects the subcategory" do
      expect(html).to have_select("transaction_form_subcategory_id", selected: subcategory.name)
    end

    it "preselects the account" do
      expect(html).to have_select("transaction_form_account_id", selected: transaction.account.name)
    end
  end

  context "with errors" do
    before do
      form.errors.add(:account, :blank)
      form.errors.add(:amount, :blank)
      form.errors.add(:date, :blank)
      form.errors.add(:payee, :blank)
      form.errors.add(:subcategory, :blank)
    end

    it "wraps amount field in error container" do
      expect(html).to have_css(".field_with_errors #transaction_form_amount")
    end

    it "displays account error message" do
      expect(html).to have_css("p", text: Regexp.new([
        TransactionForm.human_attribute_name(:account_id).humanize,
        t("errors.messages.blank")
      ].join('\s+'), Regexp::IGNORECASE))
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
