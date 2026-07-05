# frozen_string_literal: true

require "rails_helper"

describe "categories/summary.html+desktop.erb" do
  subject(:html) do
    render template: "categories/summary", formats: [:html], variants: [:desktop]

    rendered
  end

  let(:budget_snapshot) { instance_double(BudgetSnapshot) }
  let(:summary)         { instance_double(CategorySummary) }

  before do
    stub_template("categories/_summary.html.erb" => "SUMMARY_PARTIAL")

    assign :summary,         summary
    assign :budget_snapshot, budget_snapshot
  end

  it "renders the summary partial inside the category panel frame" do
    expect(html).to have_css("turbo-frame#category_panel", text: "SUMMARY_PARTIAL")
  end
end
