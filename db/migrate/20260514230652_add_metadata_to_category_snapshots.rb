# frozen_string_literal: true

class AddMetadataToCategorySnapshots < ActiveRecord::Migration[8.1]
  def change
    add_column :category_snapshots, :metadata, :json, default: {}, null: false
  end
end
