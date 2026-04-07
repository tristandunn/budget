# frozen_string_literal: true

class AddFrequencyToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :frequency, :integer
  end
end
