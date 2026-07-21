# frozen_string_literal: true

class AddNameToBudgets < ActiveRecord::Migration[8.1]
  def change
    change_table :budgets do |t|
      t.string :name, limit: 64

      t.change_null :name, false
    end
  end
end
