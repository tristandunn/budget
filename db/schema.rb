# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_23_031900) do
  create_table "budgets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.integer "budget_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "parent_id"
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "name"], name: "index_categories_on_budget_id_and_name", unique: true
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "category_snapshots", force: :cascade do |t|
    t.integer "amount_assigned", default: 0, null: false
    t.integer "amount_used", default: 0, null: false
    t.integer "budget_id", null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "date", "category_id"], name: "index_category_snapshots_on_budget_id_and_date_and_category_id", unique: true
    t.index ["category_id"], name: "index_category_snapshots_on_category_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "budget_id", null: false
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "category_id"], name: "index_transactions_on_budget_id_and_category_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
  end

  add_foreign_key "categories", "budgets"
  add_foreign_key "category_snapshots", "budgets"
  add_foreign_key "category_snapshots", "categories"
  add_foreign_key "transactions", "budgets"
  add_foreign_key "transactions", "categories"
end
