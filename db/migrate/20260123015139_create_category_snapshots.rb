# frozen_string_literal: true

class CreateCategorySnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :category_snapshots do |t|
      t.references :budget,   index: false, null: false, foreign_key: true
      t.references :category, index: true,  null: false, foreign_key: true

      t.integer :amount_assigned, null: false, default: 0
      t.integer :amount_used,     null: false, default: 0
      t.date    :date,            null: false

      t.index %i(budget_id date category_id), unique: true

      t.timestamps null: false
    end
  end
end
