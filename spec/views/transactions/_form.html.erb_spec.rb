# frozen_string_literal: true

require "rails_helper"

describe "transactions/_form.html.erb" do
  subject(:html) do
    render partial: "transactions/form", locals: {
      form:   form,
      method: :post,
      url:    "/test"
    }

    rendered
  end

  let(:form)        { TransactionForm.new(budget: subcategory.budget, subcategory: subcategory) }
  let(:subcategory) { build_stubbed(:category, :subcategory) }

  it "renders the amount field" do
    expect(html).to have_field("transaction_form_amount")
  end

  it "renders the payee hidden field" do
    expect(html).to have_field("transaction_form_payee", type: :hidden)
  end

  it "shows the payee placeholder when no payee is selected" do
    expect(html).to have_css(
      "[data-payee-picker-target='display']",
      text: t("transactions.form.enter_payee")
    )
  end

  it "renders the subcategory hidden field" do
    expect(html).to have_field("transaction_form_subcategory_id", type: :hidden)
  end

  context "when no subcategory is selected" do
    let(:form) { TransactionForm.new(budget: subcategory.budget) }

    it "shows the subcategory placeholder" do
      expect(html).to have_css(
        "[data-category-picker-target='display']",
        text: t("transactions.form.select_subcategory")
      )
    end
  end

  it "renders the account hidden field" do
    expect(html).to have_field("transaction_form_account_id", type: :hidden)
  end

  context "when no account is selected" do
    it "shows the account placeholder" do
      expect(html).to have_css(
        "[data-account-picker-target='display']",
        text: t("transactions.form.select_account")
      )
    end
  end

  it "renders the date field" do
    expect(html).to have_field("transaction_form_date")
  end

  it "renders the frequency hidden field" do
    expect(html).to have_field("transaction_form_frequency", type: :hidden)
  end

  it "shows the frequency placeholder when no frequency is selected" do
    expect(html).to have_css(
      "[data-frequency-picker-target='display']",
      text: t("transactions.frequency.labels.never")
    )
  end

  it "renders the memo field" do
    expect(html).to have_field("transaction_form_memo")
  end

  context "when prepopulated from a transaction" do
    let(:form)        { TransactionForm.from(transaction: transaction) }
    let(:subcategory) { create(:category, :subcategory) }

    let(:transaction) do
      create(:transaction, budget: subcategory.budget, frequency: :monthly, memo: "Memo", subcategory: subcategory)
    end

    it "prepopulates the amount" do
      expect(html).to have_field("transaction_form_amount",
                                 with: Money.from_cents(transaction.amount).format)
    end

    it "prepopulates the payee" do
      expect(html).to have_field("transaction_form_payee", type: :hidden, with: transaction.payee.name)
    end

    it "displays the payee name" do
      expect(html).to have_css(
        "[data-payee-picker-target='display']",
        text: transaction.payee.name
      )
    end

    it "prepopulates the date" do
      expect(html).to have_field("transaction_form_date", with: transaction.date.to_s)
    end

    it "prepopulates the memo" do
      expect(html).to have_field("transaction_form_memo", with: transaction.memo)
    end

    it "prepopulates the subcategory" do
      expect(html).to have_field(
        "transaction_form_subcategory_id",
        type: :hidden,
        with: subcategory.id.to_s
      )
    end

    it "displays the subcategory name" do
      expect(html).to have_css(
        "[data-category-picker-target='display']",
        text: subcategory.name
      )
    end

    it "prepopulates the account" do
      expect(html).to have_field(
        "transaction_form_account_id",
        type: :hidden,
        with: transaction.account.id.to_s
      )
    end

    it "displays the account name" do
      expect(html).to have_css(
        "[data-account-picker-target='display']",
        text: transaction.account.name
      )
    end

    it "prepopulates the frequency" do
      expect(html).to have_field(
        "transaction_form_frequency",
        type: :hidden,
        with: transaction.frequency
      )
    end

    it "displays the frequency label" do
      expect(html).to have_css(
        "[data-frequency-picker-target='display']",
        text: t("transactions.frequency.labels.#{transaction.frequency}")
      )
    end
  end
end
