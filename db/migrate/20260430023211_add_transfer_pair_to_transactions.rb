# frozen_string_literal: true

class AddTransferPairToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :transfer_pair,
                  foreign_key: { to_table: :transactions, on_delete: :nullify }
  end
end
