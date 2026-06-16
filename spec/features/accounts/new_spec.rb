# frozen_string_literal: true

require "rails_helper"

describe "Account creation", :js, :mobile do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
    visit budget_accounts_path(budget)
    find("a[aria-label='#{t("accounts.index.new")}']").click
  end

  it "creates a cash account" do
    fill_in AccountForm.human_attribute_name(:name), with: "Checking"
    click_on t("accounts.new.submit")

    expect(page).to have_css("[data-collapsible-id-value='cash'] li", text: "Checking", visible: :all)
  end

  it "creates a credit account" do
    fill_in AccountForm.human_attribute_name(:name), with: "Visa"
    choose t("accounts.form.credit"), allow_label_click: true
    click_on t("accounts.new.submit")

    expect(page).to have_css("[data-collapsible-id-value='credit'] li", text: "Visa", visible: :all)
  end

  it "renders an error when the name is taken" do
    create(:account, budget: budget, name: "Checking")

    fill_in AccountForm.human_attribute_name(:name), with: "Checking"
    click_on t("accounts.new.submit")

    expect(page).to have_css(
      "[role='alert']",
      text: "#{AccountForm.human_attribute_name(:name)} #{t("errors.messages.taken")}."
    )
  end

  it "keeps the dialog open after a validation error" do
    create(:account, budget: budget, name: "Checking")

    fill_in AccountForm.human_attribute_name(:name), with: "Checking"
    click_on t("accounts.new.submit")

    expect(page).to have_css("dialog[open] turbo-frame#account_dialog", visible: :all)
  end
end
