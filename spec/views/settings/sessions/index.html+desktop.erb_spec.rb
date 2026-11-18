# frozen_string_literal: true

require "rails_helper"

describe "settings/sessions/index.html+desktop.erb" do
  subject(:html) do
    render template: "settings/sessions/index", formats: [:html], variants: [:desktop]

    rendered
  end

  let(:agent)           { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:160.0) Gecko/20100101 Firefox/160.0" }
  let(:current_session) { create(:session, user_agent: agent) }
  let(:date)            { I18n.l(current_session.created_at.to_date, format: :full_date) }
  let(:other_session)   { create(:session, user: current_session.user, ip_address: nil, user_agent: nil) }

  before do
    Current.session = current_session

    assign :sessions, [current_session, other_session]
  end

  it "sets the page title" do
    html

    expect(view.content_for(:title)).to eq(t("settings.navigation.sessions"))
  end

  it "renders the device of a session" do
    expect(html).to have_css("li:first-child", text: "Firefox 160.0 on macOS")
  end

  it "renders the IP address of a session" do
    expect(html).to have_css("li:first-child", text: current_session.ip_address)
  end

  it "renders the created date of a session" do
    expect(html).to have_css("li:first-child", text: date)
  end

  it "marks the current session" do
    expect(html).to have_css("li:first-child", text: t("settings.sessions.index.current"))
  end

  it "renders a revoke button for other sessions" do
    expect(html).to have_css("li:last-child form[action='#{account_session_path(other_session)}'] button",
                             text: t("settings.sessions.index.revoke.submit"))
  end

  it "renders a placeholder when the device is unknown" do
    expect(html).to have_css("li:last-child", text: t("settings.sessions.index.unknown_device"))
  end

  it "renders a placeholder when the location is unknown" do
    expect(html).to have_css("li:last-child", text: t("settings.sessions.index.unknown_location"))
  end

  it "renders a button to revoke all other sessions" do
    expect(html).to have_css("form[action='#{account_sessions_path}'] button",
                             text: t("settings.sessions.index.revoke_others.submit"))
  end

  it "does not mark other sessions" do
    expect(html).to have_no_css("li:last-child", text: t("settings.sessions.index.current"))
  end

  it "does not render a revoke button for the current session" do
    expect(html).to have_no_css("li:first-child button")
  end

  context "without other sessions" do
    before do
      assign :sessions, [current_session]
    end

    it "does not render a button to revoke all other sessions" do
      expect(html).to have_no_css("form[action='#{account_sessions_path}']")
    end
  end
end
