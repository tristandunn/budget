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
    stub_template("snoozes/_response.turbo_stream.erb" => "RESPONSE_PARTIAL")

    assign :budget,          budget
    assign :category,        subcategory
    assign :budget_snapshot, budget_snapshot
  end

  it "renders the response partial" do
    expect(html).to include("RESPONSE_PARTIAL")
  end
end
