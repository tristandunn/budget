# frozen_string_literal: true

class AddStatusToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :status, :integer, default: 0, null: false
    add_index :transactions, %i(account_id status)
  end
end
