# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :budget,   index: false, null: false, foreign_key: true
      t.references :category, index: true,  null: true,  foreign_key: true

      t.integer :amount, null: false

      t.timestamps null: false

      t.index %i(budget_id category_id)
    end
  end
end
