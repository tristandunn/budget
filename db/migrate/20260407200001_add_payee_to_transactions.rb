# frozen_string_literal: true

class AddPayeeToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :payee, foreign_key: true
  end
end
