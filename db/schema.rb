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

ActiveRecord::Schema[8.1].define(version: 2026_04_07_200002) do
  create_table "accounts", force: :cascade do |t|
    t.integer "balance", default: 0, null: false
    t.integer "budget_id", null: false
    t.datetime "created_at", null: false
    t.boolean "credit", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "name"], name: "index_accounts_on_budget_id_and_name", unique: true
  end

  create_table "budgets", force: :cascade do |t|
    t.integer "available_to_assign", default: 0, null: false
    t.datetime "created_at", null: false
    t.json "settings", default: {}, null: false
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

  create_table "payees", force: :cascade do |t|
    t.integer "budget_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "name"], name: "index_payees_on_budget_id_and_name", unique: true
    t.index ["budget_id"], name: "index_payees_on_budget_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "amount", null: false
    t.integer "budget_id", null: false
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "frequency"
    t.string "memo"
    t.integer "payee_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "date"], name: "index_transactions_on_account_id_and_date"
    t.index ["account_id", "status"], name: "index_transactions_on_account_id_and_status"
    t.index ["budget_id", "date", "created_at"], name: "index_transactions_on_budget_id_and_date_and_created_at"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["payee_id"], name: "index_transactions_on_payee_id"
  end

  add_foreign_key "accounts", "budgets"
  add_foreign_key "categories", "budgets"
  add_foreign_key "category_snapshots", "budgets"
  add_foreign_key "category_snapshots", "categories"
  add_foreign_key "payees", "budgets"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "budgets"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "payees"
end
