# frozen_string_literal: true

module Transactions
  class CategoryPicker
    Group = Data.define(:name, :items)
    Item  = Data.define(:id, :name, :amount_remaining, :selected)

    attr_reader :groups

    def initialize(form:)
      @form   = form
      @groups = categories.filter_map do |parent|
        group_from(parent)
      end
    end

    private

    attr_reader :form

    # Return the budget snapshot for the current month.
    #
    # @return [BudgetSnapshot] The budget snapshot for the current month.
    def budget_snapshot
      @budget_snapshot ||= BudgetSnapshot.new(form.budget)
    end

    # Return the budget's parent categories with subcategories eagerly loaded,
    # sorted by position.
    #
    # @return [Array<Category>] The budget's parent categories sorted by position.
    def categories
      @categories ||= form.budget.categories.includes(:subcategories).sort_by(&:position)
    end

    # Build a Group value object for the given parent category.
    #
    # @param category [Category] The parent category to build a group for.
    # @return [Group] When the category has subcategories.
    # @return [nil] When the category has no subcategories.
    def group_from(category)
      items = category.subcategories_by_position.map do |subcategory|
        item_from(subcategory)
      end

      if items.any?
        Group.new(name: category.name, items: items)
      end
    end

    # Build an Item value object for the given subcategory.
    #
    # @param subcategory [Category] The subcategory to build an item for.
    # @return [Item] The item for display in the picker.
    def item_from(subcategory)
      Item.new(
        amount_remaining: budget_snapshot.snapshot_for(subcategory.id).amount_remaining,
        id:               subcategory.id,
        name:             subcategory.name,
        selected:         form.subcategory == subcategory
      )
    end
  end
end
