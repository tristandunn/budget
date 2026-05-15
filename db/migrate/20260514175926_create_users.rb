# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email,           null: false, limit: 255
      t.string :password_digest, null: false, limit: 60

      t.timestamps

      t.index :email, unique: true
    end
  end
end
