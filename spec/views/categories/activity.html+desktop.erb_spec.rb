# frozen_string_literal: true

require "rails_helper"

describe "categories/activity.html+desktop.erb" do
  subject(:html) do
    render template: "categories/activity", formats: [:html], variants: [:desktop]

    rendered
  end

  let(:budget_snapshot) { BudgetSnapshot.new(subcategory.budget) }
  let(:subcategory)     { create(:category, :subcategory) }
  let(:transactions)    { [] }

  before do
    assign :budget_snapshot, budget_snapshot
    assign :category,        subcategory
    assign :transactions,    transactions
  end

  it "renders the column headings" do
    expect(html).to have_css("th", text: t("categories.activity.date"))
      .and(have_css("th", text: t("categories.activity.payee")))
      .and(have_css("th", text: t("categories.activity.memo")))
      .and(have_css("th", text: t("categories.activity.amount")))
  end

  context "without transactions" do
    it "renders the empty message inside the activity frame" do
      expect(html).to have_css("turbo-frame##{dom_id(subcategory, :activity)}", text: t("categories.activity.empty"))
    end

    it "spans the empty message across every column" do
      expect(html).to have_css("td[colspan='4']", text: t("categories.activity.empty"))
    end
  end

  context "with transactions" do
    let(:payee)        { create(:payee, budget: subcategory.budget) }
    let(:transaction)  { create(:transaction, payee: payee, memo: "Coffee.") }
    let(:transactions) { [transaction] }

    it "renders the date" do
      expect(html).to have_css("td", text: l(transaction.date, format: :numeric))
    end

    it "renders the payee" do
      expect(html).to have_css("td", text: payee.name)
    end

    it "renders the memo" do
      expect(html).to have_css("td", text: transaction.memo)
    end

    it "renders the amount" do
      expect(html).to have_css("td", text: number_to_money(transaction.amount))
    end
  end
end
