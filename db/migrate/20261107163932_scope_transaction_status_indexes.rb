# frozen_string_literal: true

class ScopeTransactionStatusIndexes < ActiveRecord::Migration[8.1]
  def change
    change_table :transactions do |table|
      table.index %i(budget_id status date)
      table.index %i(category_id status date)
      table.remove_index %i(status date)
      table.remove_index :category_id
    end
  end
end
