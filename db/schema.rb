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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140705230607) do

  create_table "categories_caches", :force => true do |t|
    t.text     "categories",    :limit => 16777215
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.datetime "last_verified"
    t.string   "digest"
  end

  add_index "categories_caches", ["created_at"], :name => "index_categories_caches_on_created_at"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "flags", :force => true do |t|
    t.string   "type"
    t.string   "status",           :default => "new"
    t.string   "venueId"
    t.integer  "user_id"
    t.string   "secondaryVenueId"
    t.string   "primaryName"
    t.string   "secondaryName"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.string   "problem"
    t.datetime "submitted_at"
    t.string   "resolved_details"
    t.datetime "last_checked"
    t.string   "itemId"
    t.string   "itemName"
    t.string   "comment"
    t.integer  "job_id"
    t.datetime "scheduled_at"
    t.text     "edits"
    t.string   "creatorId"
    t.string   "creatorName"
    t.text     "venues_details"
  end

  add_index "flags", ["secondaryVenueId"], :name => "index_flags_on_secondaryVenueId"
  add_index "flags", ["status"], :name => "index_flags_on_status"
  add_index "flags", ["user_id", "status", "created_at"], :name => "index_flags_on_user_id_and_status_and_created_at"
  add_index "flags", ["user_id", "status", "creatorId", "type"], :name => "index_flags_on_user_id_and_status_and_creatorId_and_type"
  add_index "flags", ["user_id", "status", "secondaryVenueId", "type"], :name => "index_flags_on_user_id_and_status_and_secondaryVenueId_and_type"
  add_index "flags", ["user_id", "status", "venueId", "type"], :name => "index_flags_on_user_id_and_status_and_venueId_and_type"
  add_index "flags", ["venueId"], :name => "index_flags_on_venueId"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "level"
    t.string   "token"
    t.boolean  "enabled"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.string   "uid"
    t.text     "user_cache", :limit => 16777215
    t.datetime "cached_at"
    t.string   "hometown"
  end

  add_index "users", ["token"], :name => "index_users_on_token"
  add_index "users", ["uid"], :name => "index_users_on_uid"

end
