# frozen_string_literal: true

require "rails_helper"

describe Transactions::CategoryPicker do
  describe "#groups" do
    subject(:groups) do
      described_class.new(form: form).groups
    end

    let(:budget)      { create(:budget) }
    let(:food)        { create(:category, budget: budget, name: "Food") }
    let(:form)        { TransactionForm.new(budget: budget, subcategory: subcategory) }
    let(:subcategory) { nil }

    let(:groceries) do
      create(:category, :subcategory,
             parent:        food,
             budget:        budget,
             name:          "Groceries",
             with_snapshot: false)
    end

    before do
      groceries
      create(:category, budget: budget, name: "Empty Parent")
    end

    it "returns a group per parent with subcategories" do
      expect(groups).to contain_exactly(an_object_having_attributes(name: "Food"))
    end

    it "returns an item per subcategory" do
      expect(groups.first.items).to contain_exactly(
        an_object_having_attributes(
          amount_available: 0,
          id:               groceries.id,
          name:             "Groceries",
          selected:         false
        )
      )
    end

    context "with snapshots across multiple months for the subcategory" do
      before do
        create(
          :category_snapshot,
          amount_assigned: 10_000,
          amount_used:     2_500,
          budget:          budget,
          category:        groceries,
          date:            Date.current.beginning_of_month
        )
        create(
          :category_snapshot,
          amount_assigned: 5_000,
          amount_used:     3_000,
          budget:          budget,
          category:        groceries,
          date:            1.month.ago.beginning_of_month
        )
      end

      it "returns the available amount summed across months on the item" do
        expect(groups.first.items).to contain_exactly(an_object_having_attributes(amount_available: 9_500))
      end
    end

    context "when the form's subcategory matches the item" do
      let(:subcategory) { groceries }

      it "marks the item as selected" do
        expect(groups.first.items).to contain_exactly(
          an_object_having_attributes(selected: true)
        )
      end
    end

    context "when the form's subcategory does not match the item" do
      let(:subcategory) { create(:category, :subcategory, with_snapshot: false) }

      it "does not mark the item as selected" do
        expect(groups.first.items).to contain_exactly(an_object_having_attributes(selected: false))
      end
    end
  end
end
