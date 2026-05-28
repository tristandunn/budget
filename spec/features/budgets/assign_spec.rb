# frozen_string_literal: true

require "rails_helper"

describe "Assigning to a subcategory", :js do
  let(:budget)      { create(:budget, available_to_assign: 100_000) }
  let(:parent)      { create(:category, budget: budget, with_snapshot: false) }
  let(:subcategory) { create(:category, :subcategory, budget: budget, parent: parent, with_snapshot: false) }

  before do
    sign_in_for(budget)
  end

  context "when on the current month" do
    before do
      create_snapshots_for(Date.current.beginning_of_month)
      visit budget_path(budget)
      assign_amount("250.00")
    end

    it "updates the assigned amount" do
      expect(page).to have_text("$250.00")
    end

    it "updates the available to assign amount" do
      expect(page).to have_text("$750.00")
    end
  end

  context "when on a different month" do
    let(:next_month) { 1.month.from_now.beginning_of_month }

    before do
      create_snapshots_for(Date.current.beginning_of_month, amount_assigned: 1)
      create_snapshots_for(next_month)
      visit budget_path(budget)
      click_on "next-month"
      assign_amount("250.00")
    end

    it "stays on the navigated month after assigning" do
      expect(page).to have_text(next_month.strftime("%b %Y"))
    end

    it "updates the assigned amount" do
      expect(page).to have_text("$250.00")
    end

    it "updates the available to assign amount" do
      expect(page).to have_text("$750.00")
    end
  end

  context "when canceling with escape" do
    before do
      create_snapshots_for(Date.current.beginning_of_month)
      visit budget_path(budget)
      assign_amount("250.00", with: :escape)
    end

    it "closes the editor" do
      expect(page).to have_no_field("assignment_form_amount")
    end

    it "keeps the existing assigned amount" do
      expect(page).to have_link("$0.00")
    end
  end

  private

  def assign_amount(amount, with: :return)
    find("tbody td a", text: "$0.00").click
    fill_in "assignment_form_amount", with: amount
    find_by_id("assignment_form_amount").native.send_keys(with)
  end

  def create_parent_snapshot(date, amount_assigned: 0)
    create(:category_snapshot,
           budget:          budget,
           category:        parent,
           date:            date,
           amount_assigned: amount_assigned)
  end

  def create_subcategory_snapshot(date, amount_assigned: 0)
    create(:category_snapshot,
           budget:          budget,
           category:        subcategory,
           date:            date,
           amount_assigned: amount_assigned)
  end

  def create_snapshots_for(date, amount_assigned: 0)
    create_subcategory_snapshot(date, amount_assigned: amount_assigned)
    create_parent_snapshot(date, amount_assigned: amount_assigned)
  end
end
