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

ActiveRecord::Schema.define(version: 20150203114252) do

  create_table "comm_peers", force: true do |t|
    t.integer  "comm_setting_id", null: false
    t.integer  "peer_id",         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "granted_by_peer"
    t.text     "note_follower"
    t.text     "note_followed"
  end

  add_index "comm_peers", ["comm_setting_id"], name: "index_comm_peers_on_comm_setting_id", using: :btree

  create_table "comm_settings", force: true do |t|
    t.integer  "user_id",                null: false
    t.string   "channel_enc_key",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sys_channel_enc_key"
    t.string   "current_faye_client_id"
    t.datetime "unsubscribe_ts"
  end

  add_index "comm_settings", ["channel_enc_key"], name: "index_comm_settings_on_channel_enc_key", using: :btree
  add_index "comm_settings", ["user_id"], name: "index_comm_settings_on_user_id", using: :btree

  create_table "commits", force: true do |t|
    t.integer  "user_id"
    t.string   "hash_id"
    t.datetime "timestamp"
    t.integer  "local_time_secs"
  end

  add_index "commits", ["hash_id"], name: "index_commits_on_hash_id", using: :btree
  add_index "commits", ["timestamp"], name: "index_commits_on_timestamp", using: :btree

  create_table "locations", force: true do |t|
    t.decimal  "latitude",        precision: 10, scale: 7, null: false
    t.decimal  "longitude",       precision: 10, scale: 7, null: false
    t.text     "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "commit_hash"
    t.integer  "local_time_secs"
  end

  add_index "locations", ["latitude", "longitude"], name: "index_locations_on_latitude_and_longitude", using: :btree

  create_table "locations_users", force: true do |t|
    t.integer  "location_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "note"
  end

  add_index "locations_users", ["location_id"], name: "index_locations_users_on_location_id", using: :btree
  add_index "locations_users", ["user_id"], name: "index_locations_users_on_user_id", using: :btree

  create_table "poi_notes", force: true do |t|
    t.integer  "poi_id"
    t.integer  "user_id"
    t.text     "text"
    t.integer  "comments_on_id"
    t.integer  "attachment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "commit_hash"
    t.integer  "local_time_secs"
  end

  add_index "poi_notes", ["comments_on_id"], name: "index_poi_notes_on_comments_on_id", using: :btree
  add_index "poi_notes", ["poi_id"], name: "index_poi_notes_on_poi_id", using: :btree
  add_index "poi_notes", ["user_id"], name: "index_poi_notes_on_user_id", using: :btree

  create_table "pois", force: true do |t|
    t.integer  "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "commit_hash"
    t.integer  "local_time_secs"
  end

  create_table "roles", force: true do |t|
    t.string "name", null: false
  end

  create_table "upload_entities_embeds", force: true do |t|
    t.integer  "upload_id"
    t.string   "embed_type"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "upload_entities_embeds", ["upload_id"], name: "index_upload_entities_embeds_on_upload_id", using: :btree

  create_table "upload_entities_mediafiles", force: true do |t|
    t.integer  "upload_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "upload_entities_mediafiles", ["upload_id"], name: "index_upload_entities_mediafiles_on_upload_id", using: :btree

  create_table "uploads", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "poi_note_id"
    t.integer  "entity_id"
    t.string   "entity_type"
  end

  add_index "uploads", ["entity_id", "entity_type"], name: "index_uploads_on_entity_id_and_entity_type", using: :btree

  create_table "user_snapshots", force: true do |t|
    t.integer  "user_id"
    t.integer  "location_id"
    t.decimal  "lat",         precision: 10, scale: 7
    t.decimal  "lng",         precision: 10, scale: 7
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "commit_id"
  end

  add_index "user_snapshots", ["user_id"], name: "index_user_snapshots_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "username"
    t.string   "email",                              null: false
    t.string   "encrypted_password",                 null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "home_base_id"
    t.integer  "search_radius_meters"
    t.string   "foto_file_name"
    t.string   "foto_content_type"
    t.integer  "foto_file_size"
    t.datetime "foto_updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
