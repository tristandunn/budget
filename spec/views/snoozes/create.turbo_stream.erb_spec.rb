# frozen_string_literal: true

require "rails_helper"

describe "snoozes/create.turbo_stream.erb" do
  subject(:html) do
    render template: "snoozes/create", formats: [:turbo_stream]

    rendered
  end

  let(:budget)          { subcategory.budget }
  let(:budget_snapshot) { BudgetSnapshot.new(budget) }
  let(:subcategory)     { build_stubbed(:category, :subcategory) }

  before do
    stub_template("categories/_target_and_available.turbo_stream.erb" => "TARGET_AND_AVAILABLE_PARTIAL")

    assign :budget,          budget
    assign :category,        subcategory
    assign :budget_snapshot, budget_snapshot
  end

  it "renders the target and available partial" do
    expect(html).to include("TARGET_AND_AVAILABLE_PARTIAL")
  end
end
