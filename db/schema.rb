# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_05_10_203301) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_requests", force: :cascade do |t|
    t.uuid "from_id", null: false
    t.uuid "to_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["from_id"], name: "index_active_requests_on_from_id"
    t.index ["to_id"], name: "index_active_requests_on_to_id"
  end

  create_table "games", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "state"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "turn"
  end

  create_table "players", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "games_id", null: false
    t.string "uniq_pub_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["games_id"], name: "index_players_on_games_id"
    t.index ["uniq_pub_name"], name: "index_players_on_uniq_pub_name", unique: true
  end

  add_foreign_key "active_requests", "players", column: "from_id"
  add_foreign_key "active_requests", "players", column: "to_id"
  add_foreign_key "players", "games", column: "games_id"
end
