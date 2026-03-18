# frozen_string_literal: true

class AddIndexToTransactionsOnBudgetIdDateCreatedAt < ActiveRecord::Migration[8.1]
  def change
    add_index :transactions, %i(budget_id date created_at)
  end
end
