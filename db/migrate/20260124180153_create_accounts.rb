# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.references :budget, index: false, null: false, foreign_key: true

      t.string  :name,    null: false
      t.integer :balance, null: false, default: 0
      t.boolean :credit,  null: false, default: false

      t.index %i(budget_id name), unique: true

      t.timestamps null: false
    end
  end
end
