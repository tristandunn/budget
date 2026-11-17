# frozen_string_literal: true

class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user,       null: false, foreign_key: true
      t.string     :token,      null: false, limit: 255
      t.string     :ip_address, limit: 45
      t.string     :user_agent, limit: 1024

      t.timestamps

      t.index :token, unique: true
    end
  end
end
