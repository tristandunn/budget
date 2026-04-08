# frozen_string_literal: true

class CreatePayees < ActiveRecord::Migration[8.1]
  def change
    create_table :payees do |t|
      t.references :budget, null: false, foreign_key: true

      t.string :name, null: false
      t.timestamps

      t.index %i(budget_id name), unique: true
    end
  end
end
