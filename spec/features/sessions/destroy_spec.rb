# frozen_string_literal: true

require "rails_helper"

describe "Destroying a session" do
  before do
    create(:budget)

    sign_in

    visit root_path
  end

  it "successfully" do
    sign_out

    expect(page).to have_css("h1", text: t("sessions.new.title"))
  end
end
