# frozen_string_literal: true

require "rails_helper"

describe "Budget" do
  context "with a budget" do
    before do
      create(:budget)
    end

    it "renders the current month and year" do
      visit "/"

      expect(page).to have_content(Date.current.strftime("%B %Y"))
    end
  end
end
