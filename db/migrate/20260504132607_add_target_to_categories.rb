# frozen_string_literal: true

class AddTargetToCategories < ActiveRecord::Migration[8.1]
  def change
    change_table :categories do |t|
      t.integer :target_type
      t.integer :target_amount
    end
  end
end
