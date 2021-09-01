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

ActiveRecord::Schema.define(version: 2021_09_01_015343) do

  create_table "active_storage_attachments", charset: "utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audits", charset: "utf8", force: :cascade do |t|
    t.integer "execution_reason_id"
    t.boolean "primary"
    t.timestamp "performance_audit_enqueued_at"
    t.string "performance_audit_url"
    t.timestamp "created_at"
    t.text "performance_audit_error_message"
    t.boolean "is_baseline"
    t.boolean "throttled", default: false
    t.float "seconds_to_complete_performance_audit"
    t.bigint "tag_version_id"
    t.bigint "tag_id"
    t.integer "performance_audit_iterations"
    t.index ["execution_reason_id"], name: "index_audits_on_execution_reason_id"
    t.index ["tag_id"], name: "index_audits_on_tag_id"
    t.index ["tag_version_id"], name: "index_audits_on_tag_version_id"
  end

  create_table "domain_scans", charset: "utf8", force: :cascade do |t|
    t.integer "domain_id"
    t.datetime "scan_enqueued_at"
    t.datetime "scan_completed_at"
    t.text "error_message"
    t.string "url"
    t.index ["domain_id"], name: "index_domain_scans_on_domain_id"
  end

  create_table "domains", charset: "utf8", force: :cascade do |t|
    t.bigint "organization_id"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_domains_on_organization_id"
    t.index ["url"], name: "index_domains_on_url"
  end

  create_table "email_notification_subscribers", charset: "utf8", force: :cascade do |t|
    t.string "type"
    t.integer "user_id"
    t.bigint "tag_id"
    t.index ["tag_id"], name: "index_email_notification_subscribers_on_tag_id"
    t.index ["user_id"], name: "index_email_notification_subscribers_on_user_id"
  end

  create_table "execution_reasons", charset: "utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "non_third_party_url_patterns", charset: "utf8", force: :cascade do |t|
    t.bigint "domain_id"
    t.string "pattern"
    t.index ["domain_id"], name: "index_non_third_party_url_patterns_on_domain_id"
  end

  create_table "organization_users", charset: "utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_organization_users_on_organization_id"
    t.index ["user_id"], name: "index_organization_users_on_user_id"
  end

  create_table "organizations", charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tag_version_retention_count"
    t.integer "tag_check_retention_count"
  end

  create_table "performance_audit_logs", charset: "utf8", force: :cascade do |t|
    t.integer "performance_audit_id"
    t.text "logs", size: :long
    t.index ["performance_audit_id"], name: "index_performance_audit_logs_on_performance_audit_id"
  end

  create_table "performance_audits", charset: "utf8", force: :cascade do |t|
    t.integer "audit_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "dom_complete"
    t.float "dom_interactive"
    t.float "first_contentful_paint"
    t.float "script_duration"
    t.float "layout_duration"
    t.float "task_duration"
    t.float "tagsafe_score"
    t.float "tagsafe_score_standard_deviation"
    t.index ["audit_id"], name: "index_performance_audit_averages_on_audit_id"
  end

  create_table "roles", charset: "utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "roles_users", charset: "utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id"], name: "index_roles_users_on_user_id"
  end

  create_table "slack_notification_subscribers", charset: "utf8", force: :cascade do |t|
    t.string "type"
    t.string "channel"
    t.bigint "tag_id"
    t.index ["tag_id"], name: "index_slack_notification_subscribers_on_tag_id"
  end

  create_table "slack_settings", charset: "utf8", force: :cascade do |t|
    t.integer "organization_id"
    t.string "access_token"
    t.string "app_id"
    t.string "team_id"
    t.string "team_name"
    t.index ["organization_id"], name: "index_slack_settings_on_organization_id"
  end

  create_table "tag_allowed_performance_audit_third_party_urls", charset: "utf8", force: :cascade do |t|
    t.string "url_pattern"
    t.bigint "tag_id"
    t.index ["tag_id"], name: "index_tag_allowed_performance_audit_third_party_urls_on_tag_id"
  end

  create_table "tag_check_region", charset: "utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "tag_checks", charset: "utf8", force: :cascade do |t|
    t.float "response_time_ms"
    t.integer "response_code"
    t.timestamp "created_at"
    t.bigint "tag_id"
    t.bigint "tag_check_region_id"
    t.index ["tag_check_region_id"], name: "index_tag_checks_on_tag_check_region_id"
    t.index ["tag_id"], name: "index_tag_checks_on_tag_id"
  end

  create_table "tag_image_domain_lookup_patterns", charset: "utf8", force: :cascade do |t|
    t.string "url_pattern"
    t.bigint "tag_id"
    t.index ["tag_id"], name: "index_tag_image_domain_lookup_patterns_on_tag_id"
  end

  create_table "tag_images", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tag_preferences", charset: "utf8", force: :cascade do |t|
    t.boolean "should_run_audit"
    t.string "url_to_audit"
    t.integer "num_test_iterations"
    t.bigint "tag_id"
    t.boolean "monitor_changes"
    t.boolean "is_allowed_third_party_tag"
    t.boolean "is_third_party_tag"
    t.boolean "should_log_tag_checks"
    t.boolean "consider_query_param_changes_new_tag"
    t.integer "throttle_minute_threshold"
    t.index ["tag_id"], name: "index_tag_preferences_on_tag_id"
  end

  create_table "tag_versions", charset: "utf8", force: :cascade do |t|
    t.integer "bytes"
    t.string "hashed_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "most_recent"
    t.bigint "tag_id"
    t.index ["tag_id"], name: "index_tag_versions_on_tag_id"
  end

  create_table "tags", charset: "utf8", force: :cascade do |t|
    t.bigint "domain_id"
    t.string "friendly_name"
    t.timestamp "removed_from_site_at"
    t.timestamp "created_at"
    t.text "full_url"
    t.string "url_domain"
    t.string "url_path"
    t.text "url_query_param"
    t.timestamp "content_changed_at"
    t.bigint "tag_image_id"
    t.index ["domain_id"], name: "index_tags_on_domain_id"
    t.index ["tag_image_id"], name: "index_tags_on_tag_image_id"
  end

  create_table "urls_to_audits", charset: "utf8", force: :cascade do |t|
    t.bigint "tags_id"
    t.string "url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["tags_id"], name: "index_urls_to_audits_on_tags_id"
  end

  create_table "urls_to_scans", charset: "utf8", force: :cascade do |t|
    t.bigint "domain_id"
    t.string "url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["domain_id"], name: "index_urls_to_scans_on_domain_id"
  end

  create_table "user_invites", charset: "utf8", force: :cascade do |t|
    t.integer "organization_id"
    t.string "email"
    t.string "token"
    t.timestamp "expires_at"
    t.timestamp "created_at"
    t.integer "invited_by_user_id"
    t.timestamp "redeemed_at"
    t.index ["invited_by_user_id"], name: "index_user_invites_on_invited_by_user_id"
    t.index ["organization_id"], name: "index_user_invites_on_organization_id"
  end

  create_table "users", charset: "utf8", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
