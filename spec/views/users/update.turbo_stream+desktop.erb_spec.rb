# frozen_string_literal: true

require "rails_helper"

describe "users/update.turbo_stream+desktop.erb" do
  subject(:html) do
    render template: "users/update", formats: [:turbo_stream], variants: [:desktop]

    rendered
  end

  let(:user) { build_stubbed(:user) }

  before do
    assign :user, user
  end

  it "replaces the sidebar e-mail" do
    expect(html).to have_turbo_stream_element(action: "replace", target: "sidebar_user_email")
  end

  it "renders the e-mail inside the sidebar stream" do
    expect(turbo_stream_content(html, action: "replace", target: "sidebar_user_email"))
      .to include('id="sidebar_user_email"').and(include(user.email))
  end

  it "updates the account settings dialog frame" do
    expect(html).to have_turbo_stream_element(action: "update", target: "user_settings_dialog")
  end

  it "renders the dismisser controller inside the account settings dialog stream" do
    expect(turbo_stream_content(html, action: "update", target: "user_settings_dialog"))
      .to include('data-controller="dialog-dismisser"')
  end
end
