# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.references :budget, index: false, null: false, foreign_key: true
      t.references :parent, index: true,  null: true

      t.string  :name,     null: false
      t.integer :position, null: false, default: 0

      t.index %i(budget_id name), unique: true

      t.timestamps null: false
    end
  end
end
