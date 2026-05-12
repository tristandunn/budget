# frozen_string_literal: true

require "rails_helper"

describe "Renaming a payee" do
  let(:budget) { payee.budget }
  let(:payee)  { create(:payee) }

  before do
    visit budget_payees_path(budget)
    click_on payee.name
  end

  it "renames the payee" do
    fill_in "payee_form_name", with: "New Name"
    click_on t("payees.edit.submit")

    expect(page).to have_text("New Name")
  end
end
