# frozen_string_literal: true

class AddAvailableToAssignToBudgets < ActiveRecord::Migration[8.1]
  def change
    change_table :budgets do |t|
      t.integer :available_to_assign, default: 0, null: false
    end
  end
end
