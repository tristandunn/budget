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
    expect(html).to have_css(
      "h1",
      text: I18n.l(Date.current.beginning_of_month, format: :month_and_year)
    )
  end

  it "sets the page title to the full month and year" do
    html

    expect(view.content_for(:title)).to eq(
      I18n.l(Date.current.beginning_of_month, format: :full_month_and_year)
    )
  end

  it "mounts the month navigation controller" do
    expect(html).to have_css('div[data-controller="month-navigation"]')
  end

  it "targets the previous and next month links for keyboard navigation" do
    expect(html).to have_css('a#previous-month[data-month-navigation-target="previous"]')
      .and(have_css('a#next-month[data-month-navigation-target="next"]'))
  end

  it "renders the column headers" do
    expect(html).to have_css("th", text: t("budgets.show.category"))
      .and(have_css("th", text: t("budgets.show.assigned")))
      .and(have_css("th", text: t("budgets.show.activity")))
      .and(have_css("th", text: t("budgets.show.available")))
  end

  it "renders a select all checkbox wired to the selection controller" do
    expect(html).to have_css(
      "input[type=checkbox][data-selection-target=all][data-action='selection#toggleAll']"
    )
  end

  it "labels the select all checkbox" do
    expect(html).to have_field(t("budgets.show.select_all"), type: :checkbox)
  end

  it "renders the available to assign partial" do
    expect(html).to include("AVAILABLE_TO_ASSIGN_PARTIAL")
  end

  it "scopes the budget table and summary to the selection controller" do
    expect(html).to have_css("div[data-controller='selection']")
  end

  it "carries the summary url on the selection controller" do
    expect(html).to have_css(
      "div[data-controller='selection']" \
      "[data-selection-summary-url-value='#{summary_budget_categories_path(subcategory.budget,
                                                                           year:  budget_snapshot.date.year,
                                                                           month: budget_snapshot.date.month)}']"
    )
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

  it "renders the category rename dialog" do
    expect(html).to have_css(
      "dialog#category_rename_dialog_modal turbo-frame#category_rename_dialog"
    )
  end

  context "when on the current month" do
    it "renders the month and year as plain text" do
      expect(html).to have_no_link(
        I18n.l(Date.current.beginning_of_month, format: :month_and_year)
      )
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
        I18n.l(next_month.to_date, format: :month_and_year),
        href: budget_path(subcategory.budget)
      )
    end
  end
end
