# frozen_string_literal: true

class ImproveTransactionIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :transactions, %i(account_id status)
    remove_index :transactions, %i(account_id date)

    add_index :transactions, %i(account_id status date created_at)
    add_index :transactions, %i(account_id date created_at)
    add_index :transactions, %i(status date)
  end
end
