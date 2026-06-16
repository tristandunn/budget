# frozen_string_literal: true

require "rails_helper"

describe "Destroying a session" do
  before do
    budget = create(:budget)

    sign_in_for(budget)
    visit budget_path(budget)
  end

  it "successfully" do
    sign_out

    expect(page).to have_css("h1", text: t("sessions.new.title"))
  end

  context "when on a mobile browser", :mobile do
    it "successfully" do
      sign_out

      expect(page).to have_css("h1", text: t("sessions.new.title"))
    end
  end
end
