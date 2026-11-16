# frozen_string_literal: true

require "rails_helper"

describe "Password changing" do
  let(:budget)           { create(:budget, user: create(:user, password: current_password)) }
  let(:current_password) { "old-password" }

  before do
    sign_in_for(budget)
    visit account_password_path
  end

  it "changes the password and confirms the change" do
    fill_in "password_form_current_password",      with: current_password
    fill_in "password_form_password",              with: "new-password"
    fill_in "password_form_password_confirmation", with: "new-password"
    click_on t("settings.passwords.show.submit")

    expect(page).to have_css("[role='status']", text: t("settings.passwords.update.success"))
  end

  it "shows an error when the current password is incorrect" do
    fill_in "password_form_current_password",      with: "wrong-password"
    fill_in "password_form_password",              with: "new-password"
    fill_in "password_form_password_confirmation", with: "new-password"
    click_on t("settings.passwords.show.submit")

    expect(page).to have_css(
      "[role='alert']",
      text: t("activemodel.errors.models.password_form.attributes.current_password.incorrect")
    )
  end
end
