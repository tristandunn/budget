# frozen_string_literal: true

class AddSettingsToBudgets < ActiveRecord::Migration[8.1]
  def change
    add_column :budgets, :settings, :json, default: {}, null: false
  end
end
