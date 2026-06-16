# frozen_string_literal: true

require "rails_helper"

describe "budgets/show.html+desktop.erb" do
  subject(:html) do
    render template: "budgets/show", formats: [:html], variants: [:desktop]

    rendered
  end

  let(:budget_snapshot) { BudgetSnapshot.new(subcategory.budget) }
  let(:subcategory)     { create(:category, :subcategory) }

  before do
    stub_template("shared/_sidebar.html.erb"              => "SIDEBAR_PARTIAL")
    stub_template("budgets/_available_to_assign.html.erb" => "AVAILABLE_TO_ASSIGN_PARTIAL")
    stub_template("budgets/_summary.html.erb"             => "SUMMARY_PARTIAL")
    stub_template("categories/_category_header.html.erb"  => "CATEGORY_HEADER_PARTIAL")
    stub_template("categories/_subcategory_row.html.erb"  => "SUBCATEGORY_ROW_PARTIAL")

    assign :budget,          subcategory.budget
    assign :budget_snapshot, budget_snapshot
  end

  it "renders the sidebar" do
    expect(html).to include("SIDEBAR_PARTIAL")
  end

  it "renders the header with the current month and year" do
    expect(html).to have_css("h1", text: Date.current.beginning_of_month.strftime("%b %Y"))
  end

  it "renders the column headers" do
    expect(html).to have_css("th", text: t("budgets.show.category"))
      .and(have_css("th", text: t("budgets.show.assigned")))
      .and(have_css("th", text: t("budgets.show.activity")))
      .and(have_css("th", text: t("budgets.show.available")))
  end

  it "renders the available to assign partial" do
    expect(html).to include("AVAILABLE_TO_ASSIGN_PARTIAL")
  end

  it "renders the summary partial" do
    expect(html).to include("SUMMARY_PARTIAL")
  end

  it "renders the category header partial" do
    expect(html).to include("CATEGORY_HEADER_PARTIAL")
  end

  context "when the only category is an inflow category" do
    let(:subcategory) { create(:category, :inflow_subcategory) }

    it "does not render the category header partial" do
      expect(html).to have_no_text("CATEGORY_HEADER_PARTIAL")
    end
  end

  it "renders the subcategory row partial" do
    expect(html).to include("SUBCATEGORY_ROW_PARTIAL")
  end

  it "renders the category details dialog" do
    expect(html).to have_css("dialog#category_dialog_modal turbo-frame#category_dialog")
  end

  it "renders the category rename dialog" do
    expect(html).to have_css(
      "dialog#category_rename_dialog_modal turbo-frame#category_rename_dialog"
    )
  end

  it "renders the category target dialog" do
    expect(html).to have_css(
      "dialog#category_target_dialog_modal turbo-frame#category_target_dialog"
    )
  end

  context "when on the current month" do
    it "renders the month and year as plain text" do
      expect(html).to have_no_link(Date.current.beginning_of_month.strftime("%b %Y"))
    end
  end

  context "when on the first month" do
    it "disables the previous month link" do
      expect(html).to have_css('a#previous-month[aria-disabled="true"]')
    end

    it "enables the next month link" do
      expect(html).to have_css("a#next-month:not([aria-disabled])")
    end
  end

  context "when on the last month" do
    let(:next_month) { 1.month.from_now.beginning_of_month }

    let(:budget_snapshot) do
      BudgetSnapshot.new(
        subcategory.budget,
        month: next_month.month.to_s,
        year:  next_month.year.to_s
      )
    end

    it "enables the previous month link" do
      expect(html).to have_css("a#previous-month:not([aria-disabled])")
    end

    it "disables the next month link" do
      expect(html).to have_css('a#next-month[aria-disabled="true"]')
    end

    it "links the month and year to the current month" do
      expect(html).to have_link(
        next_month.strftime("%b %Y"),
        href: budget_path(subcategory.budget)
      )
    end
  end
end
