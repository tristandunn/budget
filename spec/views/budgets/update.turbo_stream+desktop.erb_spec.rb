# frozen_string_literal: true

require "rails_helper"

describe "budgets/update.turbo_stream+desktop.erb" do
  subject(:html) do
    render template: "budgets/update", formats: [:turbo_stream], variants: [:desktop]

    rendered
  end

  let(:budget) { build_stubbed(:budget) }

  before do
    assign :budget, budget
  end

  it "replaces the sidebar title frame" do
    expect(html).to have_turbo_stream_element(action: "replace", target: "budget_title")
  end

  it "renders the budget name inside the title stream" do
    expect(html).to include('id="budget_title"').and(include(budget.name))
  end

  it "updates the settings dialog frame" do
    expect(html).to have_turbo_stream_element(action: "update", target: "budget_settings_dialog")
  end

  it "renders the dismisser controller inside the settings dialog stream" do
    expect(html).to include('data-controller="dialog-dismisser"')
  end
end
