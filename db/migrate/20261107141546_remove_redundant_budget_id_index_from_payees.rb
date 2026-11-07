# frozen_string_literal: true

class RemoveRedundantBudgetIdIndexFromPayees < ActiveRecord::Migration[8.1]
  def change
    change_table :payees do |table|
      table.remove_index :budget_id
    end
  end
end
