# frozen_string_literal: true

module Transactions
  class CategoryPicker
    Group = Data.define(:name, :items, :suggested)
    Item  = Data.define(:id, :name, :amount_available, :selected)

    attr_reader :groups

    def initialize(form:)
      @form   = form
      @groups = [suggested_group, *category_groups].compact
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

    # Build a group per parent category that has subcategories.
    #
    # @return [Array<Group>] The category groups in display order.
    def category_groups
      categories.filter_map do |parent|
        group_from(parent)
      end
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
        Group.new(name: category.name, items: items, suggested: false)
      end
    end

    # Build an Item value object for the given subcategory.
    #
    # @param subcategory [Category] The subcategory to build an item for.
    # @return [Item] The item for display in the picker.
    def item_from(subcategory)
      Item.new(
        amount_available: budget_snapshot.available_for(subcategory),
        id:               subcategory.id,
        name:             subcategory.name,
        selected:         form.subcategory == subcategory
      )
    end

    # Build a suggested group of the most-used subcategories for the form's
    # payee. Returns nil when there are no suggestions to show.
    #
    # @return [Group] When the payee has suggested subcategories.
    # @return [nil] When the payee is blank, unknown, or has no suggestions.
    def suggested_group
      items = suggested_subcategories.map do |subcategory|
        item_from(subcategory)
      end

      if items.any?
        Group.new(name: I18n.t("transactions.category_picker.suggested"), items: items, suggested: true)
      end
    end

    # Return the form payee's most-used subcategories, in suggestion order.
    #
    # @return [Array<Category>] The suggested subcategories, or an empty array.
    def suggested_subcategories
      payee = form.budget.payees.find_by(name: form.payee.to_s.strip)

      if payee
        subcategories = categories.flat_map(&:subcategories).index_by(&:id)

        payee.suggested_subcategory_ids.map do |id|
          subcategories.fetch(id)
        end
      else
        []
      end
    end
  end
end
