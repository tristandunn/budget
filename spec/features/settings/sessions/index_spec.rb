# frozen_string_literal: true

require "rails_helper"

describe "Sessions" do
  let(:budget) { create(:budget, user: user) }
  let(:user)   { create(:user) }

  before do
    sign_in_as(user)
  end

  it "lists the sessions and marks the current one" do
    create(:session, user: user)

    visit account_sessions_path

    expect(page).to have_css("main li", count: 2)
      .and(have_css("main li", text: t("settings.sessions.index.current"), count: 1))
  end

  it "revokes another session", :js do
    create(:session, user: user)

    visit account_sessions_path

    accept_confirm { click_button t("settings.sessions.index.revoke.submit") }

    expect(page).to have_text(t("settings.sessions.destroy.success"))
      .and(have_css("main li", count: 1))
  end
end
