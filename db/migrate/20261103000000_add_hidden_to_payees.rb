# frozen_string_literal: true

class AddHiddenToPayees < ActiveRecord::Migration[8.1]
  def change
    change_table :payees do |table|
      table.boolean :hidden, default: false, null: false
    end
  end
end
