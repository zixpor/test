# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140423041031) do

  create_table "fbdata", force: true do |t|
    t.text     "data"
    t.text     "postid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "key"
  end

  create_table "tagdbs", force: true do |t|
    t.text     "post_id"
    t.text     "profile_picture"
    t.text     "profile_url"
    t.text     "profile_name"
    t.text     "post_time"
    t.text     "type"
    t.text     "service_type"
    t.text     "picture_url"
    t.text     "video_url"
    t.text     "message"
    t.text     "source_url"
    t.text     "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
