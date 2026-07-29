# frozen_string_literal: true

require "rails_helper"

describe "Budget switching", :js do
  let(:budget)       { create(:budget) }
  let(:other_budget) { create(:budget, users: budget.users) }

  before do
    sign_in_for(other_budget)
    visit budget_path(budget)
  end

  it "switches to another budget from the budget menu" do
    find("button[aria-label='#{t("budgets.show.menu")}']").click
    click_on other_budget.name

    expect(page).to have_current_path(budget_path(other_budget))
      .and(have_css("#budget_title", text: other_budget.name))
  end
end
