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

ActiveRecord::Schema.define(version: 20150904023309) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "alerts", force: true do |t|
    t.string   "type_alert",              null: false
    t.string   "last_sent_to"
    t.datetime "last_sent_at"
    t.integer  "sent_count"
    t.datetime "resolved_at"
    t.string   "mediaspot_id"
    t.string   "mediaspot_name"
    t.string   "mediaspot_client_name"
    t.string   "mediaspot_client_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "information"
  end

  create_table "content_providers", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "technical_name"
    t.string   "aws_bucket_access_key_id"
    t.string   "aws_bucket_secret_access_key"
    t.string   "aws_bucket_region"
    t.string   "aws_bucket_name"
    t.string   "path_in_bucket"
    t.string   "unzipping_files"
  end

  create_table "logs", force: true do |t|
    t.string   "interface"
    t.string   "user_ip"
    t.text     "user"
    t.string   "action_type"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_settings", force: true do |t|
    t.text     "metadata_template"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "metadata_validation_schema"
    t.text     "tr069_hosts_white_list"
    t.text     "websocket_hosts_white_list"
    t.text     "super_admins"
  end

  create_table "sms_statuses", force: true do |t|
    t.string   "sms_id"
    t.text     "status_information"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "sent_information"
  end

  add_index "sms_statuses", ["sms_id"], name: "index_sms_statuses_on_sms_id", using: :btree

  create_table "user_content_providers", force: true do |t|
    t.integer  "user_id"
    t.integer  "content_provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                                  default: "",    null: false
    t.string   "encrypted_password",                     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                                  default: false
    t.string   "api_key"
    t.boolean  "subscribed_alert_mediaspot_offline",     default: false
    t.boolean  "subscribed_alert_sync_error",            default: false
    t.boolean  "sms_subscribed_alert_mediaspot_offline", default: false
    t.boolean  "sms_subscribed_alert_sync_error",        default: false
    t.string   "phone_number"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
