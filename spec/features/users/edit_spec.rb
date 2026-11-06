# frozen_string_literal: true

require "rails_helper"

describe "User editing" do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
    visit budget_path(budget)
  end

  context "when on a desktop browser", :js do
    before do
      find("button[aria-label='#{t("budgets.show.menu")}']").click
      find_by_id("edit-user").click
    end

    it "changes the e-mail and updates the sidebar" do
      within "#user_settings_dialog_modal" do
        fill_in "user_email", with: "new@example.com"
        click_on t("users.edit.submit")
      end

      expect(page).to have_no_css("#user_settings_dialog_modal[open]")
        .and(have_css("#sidebar_user_email", text: "new@example.com"))
    end

    it "shows an error and keeps the window open when the e-mail is invalid" do
      within "#user_settings_dialog_modal" do
        fill_in "user_email", with: "invalid@localhost"
        click_on t("users.edit.submit")
      end

      expect(page).to have_css("#user_settings_dialog_modal[open]", text: t("errors.messages.invalid"))
    end

    it "dismisses the window on escape" do
      find_by_id("user_settings_dialog_modal").send_keys(:escape)

      expect(page).to have_no_css("#user_settings_dialog_modal[open]")
    end
  end
end
