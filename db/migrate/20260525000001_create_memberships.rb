# frozen_string_literal: true

class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :budget, null: false, foreign_key: true, index: false
      t.references :user,   null: false, foreign_key: true

      t.timestamps

      t.index %i(budget_id user_id), unique: true
    end
  end
end
