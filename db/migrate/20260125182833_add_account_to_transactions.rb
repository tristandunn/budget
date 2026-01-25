# frozen_string_literal: true

class AddAccountToTransactions < ActiveRecord::Migration[8.1]
  def change
    change_table :transactions do |t|
      t.references :account, index: true, foreign_key: true
    end

    change_column_null :transactions, :account_id, false
  end
end
