# frozen_string_literal: true

require "rails_helper"

describe "transfers/new.html.erb" do
  subject(:html) do
    render template: "transfers/new", formats: [:html]

    rendered
  end

  let(:budget)   { build_stubbed(:budget) }
  let(:checking) { build_stubbed(:account, budget: budget, name: "Checking") }
  let(:savings)  { build_stubbed(:account, budget: budget, name: "Savings") }

  before do
    assign :budget,   budget
    assign :accounts, [checking, savings]
  end

  it "renders the title" do
    expect(html).to have_css("h1", text: I18n.t("transfers.new.title"))
  end

  it "submits the form to the budget transfers path" do
    expect(html).to have_css("form[action='#{budget_transfers_path(budget)}'][method='post']")
  end

  it "renders a from account select listing each account" do
    expect(html).to have_select(
      I18n.t("transfers.form.from_account_id"),
      options: %w(Checking Savings)
    )
  end

  it "renders a to account select listing each account" do
    expect(html).to have_select(
      I18n.t("transfers.form.to_account_id"),
      options: %w(Checking Savings)
    )
  end

  it "renders an amount field" do
    expect(html).to have_field(
      I18n.t("transfers.form.amount"),
      type: "number"
    )
  end

  it "renders a date field defaulting to today" do
    expect(html).to have_field(
      I18n.t("transfers.form.date"),
      type: "date",
      with: Date.current.to_s
    )
  end

  it "renders a memo field" do
    expect(html).to have_field(
      I18n.t("transfers.form.memo"),
      type: "text"
    )
  end

  it "renders the submit button" do
    expect(html).to have_button(I18n.t("transfers.new.submit"))
  end
end
