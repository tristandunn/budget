# frozen_string_literal: true

class ImproveTransactionPayeeIndexes < ActiveRecord::Migration[8.1]
  def change
    change_table :transactions do |table|
      table.index %i(payee_id date category_id)
      table.remove_index :payee_id
    end
  end
end
