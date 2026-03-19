# frozen_string_literal: true

class RemoveRedundantTransactionIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :transactions, :account_id
    remove_index :transactions, %i(budget_id category_id)
  end
end
