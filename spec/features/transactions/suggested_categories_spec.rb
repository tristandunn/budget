# frozen_string_literal: true

require "rails_helper"

describe "Transaction category suggestions" do
  let(:account) { create(:account) }
  let(:budget)  { account.budget }

  context "when editing a transaction for the payee" do
    let(:least_used) { create(:category, :subcategory, budget: budget) }
    let(:most_used)  { create(:category, :subcategory, budget: budget) }
    let(:payee)      { create(:payee, budget: budget) }

    before do
      record_subcategory_usage(payee, most_used => 2, least_used => 1)

      sign_in_for(budget)

      visit edit_budget_transaction_path(budget, payee.transactions.first)
    end

    it "lists the payee's most-used subcategories in a suggested group" do
      expect(suggested_labels).to eq([most_used.name, least_used.name])
    end
  end

  context "when selecting the payee on a new transaction", :js do
    let(:least_used) { create(:category, :subcategory, budget: budget) }
    let(:most_used)  { create(:category, :subcategory, budget: budget) }
    let(:payee)      { create(:payee, budget: budget) }

    before do
      record_subcategory_usage(payee, most_used => 2, least_used => 1)

      sign_in_for(budget)

      visit new_budget_transaction_path(budget)
    end

    it "shows the payee's most-used subcategories in the category picker" do
      select_payee(payee.name)
      open_category_picker

      expect(suggested_labels).to eq([most_used.name, least_used.name])
    end
  end

  context "when changing the payee on an existing transaction", :js do
    let(:other_payee)       { create(:payee, budget: budget) }
    let(:other_subcategory) { create(:category, :subcategory, budget: budget) }

    before do
      transaction = create(:transaction, account: account, budget: budget)
      create(:transaction, account: account, budget: budget, payee: other_payee, subcategory: other_subcategory)

      sign_in_for(budget)

      visit edit_budget_transaction_path(budget, transaction)
    end

    it "replaces the suggestions with the newly selected payee's" do
      select_payee(other_payee.name)
      open_category_picker

      expect(suggested_labels).to eq([other_subcategory.name])
    end
  end

  protected

  # Open the category picker panel.
  def open_category_picker
    find("[data-action~='click->category-picker#open']").click
  end

  # Give the payee the requested number of transactions for each subcategory.
  #
  # @param payee [Payee] The payee to record usage for.
  # @param counts [Hash{Category => Integer}] Subcategory to transaction count.
  def record_subcategory_usage(payee, counts)
    counts.each do |subcategory, count|
      create_list(:transaction, count, account: account, budget: budget, payee: payee, subcategory: subcategory)
    end
  end

  # Open the payee picker and select the option with the given name.
  #
  # @param name [String] The payee name to select.
  def select_payee(name)
    find("[data-action~='click->payee-picker#open']").click

    within "[data-payee-picker-target='picker']" do
      find("[role='option']", text: name).click
    end
  end

  # Return the labels of the items in the category picker's suggested group.
  #
  # @return [Array<String>] The suggested item labels, in display order.
  def suggested_labels
    suggested = find("[data-category-picker-target='group']",
                     text: t("transactions.category_picker.suggested"))

    within(suggested) do
      all("[data-category-picker-target='item']").pluck("data-label")
    end
  end
end
