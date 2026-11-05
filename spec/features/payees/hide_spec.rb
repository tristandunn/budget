# frozen_string_literal: true

require "rails_helper"

describe "Hiding a payee" do
  let(:budget) { payee.budget }
  let(:payee)  { create(:payee) }

  context "when hiding from the payees list" do
    before do
      sign_in_for(budget)
      visit budget_payees_path(budget)
      click_on payee.name
    end

    it "hides the payee" do
      choose t("payees.edit.hide"), allow_label_click: true
      click_on t("payees.edit.submit")

      expect(page).to have_link(href: edit_budget_payee_path(budget, payee), text: t("payees.index.hidden"))
    end
  end

  context "when picking a payee for a transaction", :js do
    let(:item) { "[data-payee-picker-target='item'][data-label='#{payee.name}']" }

    before do
      payee.update!(hidden: true)

      sign_in_for(budget)
      visit new_budget_transaction_path(budget)
      find("[data-payee-picker-target='display']").click
    end

    it "does not list the hidden payee before its name is typed" do
      expect(page).to have_no_css(item)
    end

    it "lists the hidden payee when its name is typed" do
      find("input[data-payee-picker-target='search']").send_keys(payee.name.downcase)

      expect(page).to have_css(item)
    end
  end
end
