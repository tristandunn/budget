# frozen_string_literal: true

require "rails_helper"

describe "accounts/_form.html.erb" do
  subject(:html) do
    render partial: "accounts/form", locals: {
      budget: budget,
      form:   form,
      method: method,
      url:    url
    }

    rendered
  end

  let(:budget) { create(:budget) }
  let(:form)   { AccountForm.new(account: account, budget: budget, name: account.name, credit: account.credit) }
  let(:method) { :post }
  let(:url)    { budget_accounts_path(budget) }

  context "with a new account" do
    let(:account) { budget.accounts.new }

    it "renders the name input" do
      expect(html).to have_field("account_form[name]", type: "text")
    end

    it "renders the cash radio with its label" do
      expect(html).to have_css("label[for='account_form_credit_false']", text: t("accounts.form.cash"))
    end

    it "renders the credit radio with its label" do
      expect(html).to have_css("label[for='account_form_credit_true']", text: t("accounts.form.credit"))
    end

    it "checks the cash radio by default" do
      expect(html).to have_css(
        "input[type='radio'][name='account_form[credit]'][value='false'][checked]",
        visible: :all
      )
    end

    it "does not check the credit radio by default" do
      expect(html).to have_css(
        "input[type='radio'][name='account_form[credit]'][value='true']:not([checked])",
        visible: :all
      )
    end

    it "does not render the delete button" do
      expect(html).to have_no_button(t("accounts.form.delete"))
    end
  end

  context "with a persisted cash account" do
    let(:account) { create(:account, budget: budget) }
    let(:method)  { :patch }
    let(:url)     { budget_account_path(budget, account) }

    it "checks the cash radio" do
      expect(html).to have_css(
        "input[type='radio'][name='account_form[credit]'][value='false'][checked]",
        visible: :all
      )
    end

    it "does not check the credit radio" do
      expect(html).to have_css(
        "input[type='radio'][name='account_form[credit]'][value='true']:not([checked])",
        visible: :all
      )
    end
  end

  context "with a persisted credit account" do
    let(:account) { create(:account, :credit, budget: budget) }
    let(:method)  { :patch }
    let(:url)     { budget_account_path(budget, account) }

    it "checks the credit radio" do
      expect(html).to have_css(
        "input[type='radio'][name='account_form[credit]'][value='true'][checked]",
        visible: :all
      )
    end

    it "does not check the cash radio" do
      expect(html).to have_css(
        "input[type='radio'][name='account_form[credit]'][value='false']:not([checked])",
        visible: :all
      )
    end
  end

  context "with a persisted account that has no transactions" do
    let(:account) { create(:account, budget: budget) }
    let(:method)  { :patch }
    let(:url)     { budget_account_path(budget, account) }

    it "renders the delete button" do
      expect(html).to have_button(t("accounts.form.delete"))
    end
  end

  context "with a persisted account that has transactions" do
    let(:account) { create(:account, budget: budget) }
    let(:method)  { :patch }
    let(:url)     { budget_account_path(budget, account) }

    before do
      subcategory = create(:category, :subcategory, budget: budget)
      create(:transaction, account: account, budget: budget, subcategory: subcategory)
    end

    it "does not render the delete button" do
      expect(html).to have_no_button(t("accounts.form.delete"))
    end
  end

  context "with an invalid cash submission" do
    let(:account) { budget.accounts.new }
    let(:form)    { AccountForm.new(account: account, budget: budget, name: "", credit: "false") }

    it "keeps the cash radio checked" do
      expect(html).to have_css(
        "input[type='radio'][name='account_form[credit]'][value='false'][checked]",
        visible: :all
      )
    end
  end

  context "with an invalid credit submission" do
    let(:account) { budget.accounts.new }
    let(:form)    { AccountForm.new(account: account, budget: budget, name: "", credit: "true") }

    it "keeps the credit radio checked" do
      expect(html).to have_css(
        "input[type='radio'][name='account_form[credit]'][value='true'][checked]",
        visible: :all
      )
    end
  end

  context "with name validation errors" do
    let(:account) { build(:account, budget: budget, name: "") }
    let(:form)    { AccountForm.new(account: account, budget: budget, name: "", credit: false).tap(&:save) }

    it "renders the error message" do
      expect(html).to have_css("[role='alert']",
                               normalize_ws: true,
                               text:         "#{AccountForm.human_attribute_name(:name)} #{form.errors[:name].first}.")
    end
  end
end
