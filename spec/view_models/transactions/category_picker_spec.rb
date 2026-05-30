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
      expect(groups).to contain_exactly(an_object_having_attributes(name: "Food", suggested: false))
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

    context "with category suggestions" do
      let(:form) { TransactionForm.new(budget: budget, payee: nil) }

      it "prepends a suggested group when the payee has categorized transactions" do
        payee = create(:payee, budget: budget)
        create(:transaction, budget: budget, payee: payee, subcategory: groceries)
        form = TransactionForm.new(budget: budget, payee: payee.name)

        groups = described_class.new(form: form).groups

        expect(groups.first).to have_attributes(
          items:     contain_exactly(an_object_having_attributes(id: groceries.id, name: "Groceries")),
          name:      I18n.t("transactions.category_picker.suggested"),
          suggested: true
        )
      end

      it "still includes the regular category groups below the suggested group" do
        payee = create(:payee, budget: budget)
        create(:transaction, budget: budget, payee: payee, subcategory: groceries)
        form = TransactionForm.new(budget: budget, payee: payee.name)

        expect(described_class.new(form: form).groups.map(&:name)).to eq(
          [I18n.t("transactions.category_picker.suggested"), "Food"]
        )
      end

      it "marks suggested items as selected when the form's subcategory matches" do
        payee = create(:payee, budget: budget)
        create(:transaction, budget: budget, payee: payee, subcategory: groceries)
        form = TransactionForm.new(budget: budget, payee: payee.name, subcategory: groceries)

        suggested = described_class.new(form: form).groups.first

        expect(suggested.items).to contain_exactly(an_object_having_attributes(selected: true))
      end

      it "does not include a suggested group when the payee is blank" do
        expect(described_class.new(form: form).groups.map(&:name)).not_to include(
          I18n.t("transactions.category_picker.suggested")
        )
      end

      it "does not include a suggested group when the payee does not match an existing payee" do
        form = TransactionForm.new(budget: budget, payee: "Brand New Payee")

        expect(described_class.new(form: form).groups.map(&:name)).not_to include(
          I18n.t("transactions.category_picker.suggested")
        )
      end

      it "does not include a suggested group when the matched payee has no categorized transactions" do
        payee = create(:payee, budget: budget)
        create(:transaction, budget: budget, payee: payee, subcategory: nil)
        form = TransactionForm.new(budget: budget, payee: payee.name)

        expect(described_class.new(form: form).groups.map(&:name)).not_to include(
          I18n.t("transactions.category_picker.suggested")
        )
      end
    end
  end
end
