# frozen_string_literal: true

require "rails_helper"

describe "transactions/new.html.erb" do
  subject(:html) do
    render template: "transactions/new", formats: [:html]

    rendered
  end

  let(:budget)        { category.budget }
  let(:category)      { create(:category, :subcategory) }
  let(:form)          { TransactionForm.new(budget: budget, category: category) }
  let(:subcategories) { budget.subcategories }

  before do
    assign :form, form
    assign :subcategories, subcategories
  end

  it "renders the amount field" do
    expect(html).to have_field("transaction_form_amount")
  end

  it "renders the category select" do
    expect(html).to have_select("transaction_form_subcategory_id")
  end

  it "renders the submit button" do
    expect(html).to have_button(I18n.t("transactions.new.submit"))
  end

  context "when the form has amount errors" do
    before do
      form.errors.add(:amount, "can't be blank")
    end

    it "renders the error message" do
      expect(html).to have_css("p", text: /Amount/i)
    end
  end

  context "when the form has category errors" do
    before do
      form.errors.add(:category, "must exist")
    end

    it "renders the error message" do
      expect(html).to have_css("p", text: /Category/i)
    end
  end
end
