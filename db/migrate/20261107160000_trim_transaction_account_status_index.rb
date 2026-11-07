# frozen_string_literal: true

class TrimTransactionAccountStatusIndex < ActiveRecord::Migration[8.1]
  def change
    change_table :transactions do |table|
      table.index %i(account_id status)
      table.remove_index %i(account_id status date created_at)
    end
  end
end
