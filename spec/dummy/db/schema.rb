# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2017_02_20_153105) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles", id: :serial, force: :cascade do |t|
    t.string "title"
    t.integer "rating"
    t.boolean "active"
    t.integer "user_id"
    t.jsonb "log_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.text "content"
    t.jsonb "log_data"
    t.integer "article_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_comments_on_article_id"
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.string "title"
    t.integer "rating"
    t.boolean "active"
    t.jsonb "meta"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "age"
    t.boolean "active"
    t.jsonb "extra"
    t.string "settings", array: true
    t.jsonb "log_data"
    t.datetime "time"
  end

  add_foreign_key "articles", "users"
  add_foreign_key "comments", "articles"
end
