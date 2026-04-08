# frozen_string_literal: true

class RequirePayeeOnTransactions < ActiveRecord::Migration[8.1]
  def change
    remove_column :transactions, :payee, :string
    change_column_null :transactions, :payee_id, false
  end
end
