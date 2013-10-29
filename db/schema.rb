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

ActiveRecord::Schema.define(:version => 20130911013248) do

  create_table "bookmarks", :force => true do |t|
    t.integer  "user_id",     :null => false
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "user_type"
  end

  add_index "bookmarks", ["user_id", "user_type"], :name => "index_bookmarks_on_user_id_and_user_type"

  create_table "checksum_audit_logs", :force => true do |t|
    t.string   "pid"
    t.string   "dsid"
    t.string   "version"
    t.integer  "pass"
    t.string   "expected_result"
    t.string   "actual_result"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "checksum_audit_logs", ["pid", "dsid"], :name => "by_pid_and_dsid"

  create_table "conversations", :force => true do |t|
    t.string   "subject",    :default => ""
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "domain_terms", :force => true do |t|
    t.string "model"
    t.string "term"
  end

  add_index "domain_terms", ["model", "term"], :name => "terms_by_model_and_term"

  create_table "domain_terms_local_authorities", :id => false, :force => true do |t|
    t.integer "domain_term_id"
    t.integer "local_authority_id"
  end

  add_index "domain_terms_local_authorities", ["domain_term_id", "local_authority_id"], :name => "dtla_by_ids2"
  add_index "domain_terms_local_authorities", ["local_authority_id", "domain_term_id"], :name => "dtla_by_ids1"

  create_table "follows", :force => true do |t|
    t.integer  "followable_id",                      :null => false
    t.string   "followable_type",                    :null => false
    t.integer  "follower_id",                        :null => false
    t.string   "follower_type",                      :null => false
    t.boolean  "blocked",         :default => false, :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "follows", ["followable_id", "followable_type"], :name => "fk_followables"
  add_index "follows", ["follower_id", "follower_type"], :name => "fk_follows"

  create_table "geoname", :id => false, :force => true do |t|
    t.integer  "geonameid",                      :null => false
    t.string   "name",           :limit => 200
    t.string   "asciiname",      :limit => 200
    t.string   "alternatenames", :limit => 8000
    t.float    "latitude"
    t.float    "longitude"
    t.string   "fclass",         :limit => 1
    t.string   "fcode",          :limit => 10
    t.string   "country",        :limit => 2
    t.string   "cc2",            :limit => 60
    t.string   "admin1",         :limit => 20
    t.string   "admin2",         :limit => 80
    t.string   "admin3",         :limit => 20
    t.string   "admin4",         :limit => 20
    t.integer  "population",     :limit => 8
    t.integer  "elevation"
    t.integer  "gtopo30"
    t.string   "timezone",       :limit => 40
    t.date     "moddate"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  add_index "geoname", ["geonameid", "name"], :name => "geonamename_idx", :unique => true
  add_index "geoname", ["geonameid"], :name => "geonameid_idx", :unique => true

  create_table "geoname_hierarchy", :force => true do |t|
    t.integer  "geoname_id"
    t.string   "hierarchy_tree",      :limit => 1000
    t.string   "hierarchy_tree_name", :limit => 8000
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "geoname_hierarchy", ["geoname_id", "hierarchy_tree"], :name => "geonamehierarchy_tree_idx", :unique => true
  add_index "geoname_hierarchy", ["geoname_id"], :name => "geonamehierarchy_geonameid_idx"

  create_table "geoname_search", :force => true do |t|
    t.integer  "geoname_id"
    t.string   "geo_location"
    t.string   "object_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "geoname_search", ["geo_location"], :name => "entries_by_geo_location"
  add_index "geoname_search", ["geoname_id", "object_id"], :name => "entries_by_geoname_id_and_object_id", :unique => true

  create_table "help_requests", :force => true do |t|
    t.string   "view_port"
    t.text     "current_url"
    t.string   "user_agent"
    t.string   "resolution"
    t.text     "how_can_we_help_you"
    t.integer  "user_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.boolean  "javascript_enabled"
    t.string   "release_version"
  end

  add_index "help_requests", ["created_at"], :name => "index_help_requests_on_created_at"
  add_index "help_requests", ["user_id"], :name => "index_help_requests_on_user_id"

  create_table "local_authorities", :force => true do |t|
    t.string "name"
  end

  create_table "local_authority_entries", :force => true do |t|
    t.integer "local_authority_id"
    t.string  "label"
    t.string  "uri"
  end

  add_index "local_authority_entries", ["local_authority_id", "label"], :name => "entries_by_term_and_label"
  add_index "local_authority_entries", ["local_authority_id", "uri"], :name => "entries_by_term_and_uri"

  create_table "mesh_tree_structures", :force => true do |t|
    t.string   "subject_mesh_term_id"
    t.string   "tree_structure"
    t.text     "eval_tree_path"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "mesh_tree_structures", ["subject_mesh_term_id", "tree_structure"], :name => "entries_by_term_id_and_tree_structure", :unique => true
  add_index "mesh_tree_structures", ["tree_structure"], :name => "entries_by_tree_structure"

  create_table "notifications", :force => true do |t|
    t.string   "type"
    t.text     "body"
    t.string   "subject",              :default => ""
    t.integer  "sender_id"
    t.string   "sender_type"
    t.integer  "conversation_id"
    t.boolean  "draft",                :default => false
    t.datetime "updated_at",                              :null => false
    t.datetime "created_at",                              :null => false
    t.integer  "notified_object_id"
    t.string   "notified_object_type"
    t.string   "notification_code"
    t.string   "attachment"
  end

  add_index "notifications", ["conversation_id"], :name => "index_notifications_on_conversation_id"
  add_index "notifications", ["notified_object_id", "notified_object_type"], :name => "notifications_notified_object"
  add_index "notifications", ["sender_id", "sender_type"], :name => "index_notifications_on_sender_id_and_sender_type"

  create_table "object_access", :primary_key => "access_id", :force => true do |t|
    t.datetime "date_accessed"
    t.string   "ip_address"
    t.string   "host_name"
    t.string   "user_agent"
    t.string   "request_method"
    t.string   "path_info"
    t.integer  "repo_object_id"
    t.integer  "purl_id"
  end

  create_table "purl", :primary_key => "purl_id", :force => true do |t|
    t.integer  "repo_object_id"
    t.string   "access_count"
    t.datetime "last_accessed"
    t.string   "source_app"
    t.datetime "date_created"
  end

  create_table "receipts", :force => true do |t|
    t.integer  "receiver_id"
    t.string   "receiver_type"
    t.integer  "notification_id",                                  :null => false
    t.boolean  "is_read",                       :default => false
    t.boolean  "trashed",                       :default => false
    t.boolean  "deleted",                       :default => false
    t.string   "mailbox_type",    :limit => 25
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
  end

  add_index "receipts", ["notification_id"], :name => "index_receipts_on_notification_id"
  add_index "receipts", ["receiver_id", "receiver_type"], :name => "index_receipts_on_receiver_id_and_receiver_type"

  create_table "repo_object", :primary_key => "repo_object_id", :force => true do |t|
    t.string   "filename"
    t.string   "url"
    t.datetime "date_added"
    t.string   "add_source_ip"
    t.datetime "date_modified"
    t.string   "information"
  end

  create_table "searches", :force => true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "user_type"
  end

  add_index "searches", ["user_id", "user_type"], :name => "index_searches_on_user_id_and_user_type"
  add_index "searches", ["user_id"], :name => "index_searches_on_user_id"

  create_table "single_use_links", :force => true do |t|
    t.string   "downloadKey"
    t.string   "path"
    t.string   "itemId"
    t.datetime "expires"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "subject_local_authority_entries", :force => true do |t|
    t.string   "label"
    t.string   "lower_label"
    t.string   "url"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "subject_local_authority_entries", ["lower_label"], :name => "entries_by_lower_label"

  create_table "subject_mesh_entries", :id => false, :force => true do |t|
    t.string   "subject_mesh_term_id"
    t.string   "term"
    t.text     "subject_description"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "subject_mesh_entries", ["subject_mesh_term_id", "term"], :name => "entries_by_id_and_term", :unique => true
  add_index "subject_mesh_entries", ["subject_mesh_term_id"], :name => "entries_by_subject_mesh_term_id"

  create_table "subject_mesh_synonyms", :force => true do |t|
    t.string   "subject_mesh_term_id"
    t.string   "subject_synonym"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "subject_mesh_synonyms", ["subject_mesh_term_id", "subject_synonym"], :name => "entries_by_id_and_synonyms", :unique => true

  create_table "trophies", :force => true do |t|
    t.integer  "user_id"
    t.string   "generic_file_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "trophies", ["user_id"], :name => "index_trophies_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email",                      :default => "",    :null => false
    t.string   "encrypted_password",         :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",              :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.boolean  "guest",                      :default => false
    t.string   "username",                   :default => "",    :null => false
    t.text     "group_list"
    t.datetime "groups_last_update"
    t.boolean  "agreed_to_terms_of_service", :default => false
    t.boolean  "admin",                      :default => false
    t.string   "uid"
  end

  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["uid"], :name => "index_users_on_uid", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username"

  create_table "version_committers", :force => true do |t|
    t.string   "obj_id"
    t.string   "datastream_id"
    t.string   "version_id"
    t.string   "committer_login"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

end
