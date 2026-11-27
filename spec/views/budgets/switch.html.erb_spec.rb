# frozen_string_literal: true

require "rails_helper"

describe "budgets/switch.html.erb" do
  subject(:html) do
    render template: "budgets/switch", formats: [:html]

    rendered
  end

  let(:budget)       { create(:budget) }
  let(:other_budget) { create(:budget, users: budget.users) }

  before do
    assign :budget,  budget
    assign :budgets, [budget, other_budget]
  end

  it "renders the dialog turbo frame" do
    expect(html).to have_css("turbo-frame#budget_switch_dialog")
  end

  it "renders the dialog title" do
    expect(html).to have_css("h2", text: t("budgets.switch.title"))
  end

  it "renders a done button that closes the dialog" do
    expect(html).to have_css(
      "button[data-action='dialog#close']", text: t("budgets.switch.done")
    )
  end

  it "links each budget to its budget page" do
    expect(html).to have_link(budget.name, href: budget_path(budget))
      .and(have_link(other_budget.name, href: budget_path(other_budget)))
  end

  it "breaks out of the dialog frame when following a budget" do
    expect(html).to have_css("#budget-list a[data-turbo-frame='_top']", count: 2)
  end

  it "marks the current budget" do
    expect(html).to have_css("#budget-list a[aria-current='true']", text: budget.name)
      .and(have_no_css("#budget-list a[aria-current]", text: other_budget.name))
  end
end
