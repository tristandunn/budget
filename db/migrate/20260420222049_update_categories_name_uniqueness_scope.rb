# frozen_string_literal: true

class UpdateCategoriesNameUniquenessScope < ActiveRecord::Migration[8.1]
  def change
    remove_index :categories, %i(budget_id name),
                 unique: true,
                 name:   "index_categories_on_budget_id_and_name"

    add_index :categories, %i(budget_id name),
              unique: true,
              where:  "parent_id IS NULL",
              name:   "index_categories_on_budget_id_and_name_for_parents"

    add_index :categories, %i(budget_id parent_id name),
              unique: true,
              where:  "parent_id IS NOT NULL",
              name:   "index_categories_on_budget_id_and_parent_id_and_name"
  end
end
