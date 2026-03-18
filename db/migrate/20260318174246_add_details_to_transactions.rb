# frozen_string_literal: true

class AddDetailsToTransactions < ActiveRecord::Migration[8.1]
  def change
    change_table :transactions, bulk: true do |t|
      t.date   :date
      t.string :memo
      t.string :payee

      t.index %i(account_id date)
    end

    change_column_null :transactions, :date, false
    change_column_null :transactions, :payee, false
  end
end
