# frozen_string_literal: true

require "rails_helper"

describe "User settings" do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
    visit account_path
  end

  it "changes the e-mail and confirms the change" do
    fill_in "user_email", with: "new@example.com"
    click_on t("users.show.submit")

    expect(page).to have_field("user_email", with: "new@example.com")
      .and(have_css("[role='status']", text: t("users.update.success")))
  end

  it "shows an error when the e-mail is invalid" do
    fill_in "user_email", with: "invalid@localhost"
    click_on t("users.show.submit")

    expect(page).to have_css("[role='alert']", text: t("errors.messages.invalid"))
  end

  it "returns to the budget" do
    click_on t("users.layout.back")

    expect(page).to have_current_path(budget_path(budget))
  end
end
