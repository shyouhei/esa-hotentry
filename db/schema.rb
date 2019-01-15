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

ActiveRecord::Schema.define(version: 20160407054125) do

  create_table "comments", force: :cascade do |t|
    t.string "namespace"
    t.integer "number"
    t.integer "post_id"
    t.text "url"
    t.integer "revision_number", default: 1
    t.integer "stargazers_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace", "number"], name: "index_comments_on_namespace_and_number", unique: true
    t.index ["post_id"], name: "index_comments_on_post_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "namespace"
    t.integer "number"
    t.text "name"
    t.text "url"
    t.integer "revision_number"
    t.integer "comments_count"
    t.integer "stargazers_count"
    t.integer "watchers_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace", "number"], name: "index_posts_on_namespace_and_number", unique: true
  end

end
