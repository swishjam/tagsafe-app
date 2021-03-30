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

ActiveRecord::Schema.define(version: 2021_03_29_145858) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "audits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "script_change_id"
    t.integer "script_subscriber_id"
    t.integer "execution_reason_id"
    t.boolean "primary"
    t.timestamp "performance_audit_enqueued_at"
    t.string "performance_audit_url"
    t.timestamp "created_at"
    t.text "performance_audit_error_message"
    t.boolean "is_baseline"
    t.boolean "throttled", default: false
    t.float "seconds_to_complete_performance_audit"
    t.index ["execution_reason_id"], name: "index_audits_on_execution_reason_id"
    t.index ["script_change_id"], name: "index_audits_on_script_change_id"
    t.index ["script_subscriber_id"], name: "index_audits_on_script_subscriber_id"
  end

  create_table "domain_scans", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "domain_id"
    t.datetime "scan_enqueued_at"
    t.datetime "scan_completed_at"
    t.text "error_message"
    t.index ["domain_id"], name: "index_domain_scans_on_domain_id"
  end

  create_table "domains", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "organization_id"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_domains_on_organization_id"
    t.index ["url"], name: "index_domains_on_url"
  end

  create_table "email_notification_subscribers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "type"
    t.integer "user_id"
    t.integer "script_subscriber_id"
    t.index ["script_subscriber_id"], name: "index_email_notification_subscribers_on_script_subscriber_id"
    t.index ["user_id"], name: "index_email_notification_subscribers_on_user_id"
  end

  create_table "execution_reasons", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "lint_results", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "script_change_id"
    t.string "rule_id"
    t.string "message"
    t.integer "line"
    t.integer "column"
    t.string "node_type"
    t.boolean "fatal"
    t.string "source"
    t.index ["script_change_id"], name: "index_lint_results_on_script_change_id"
  end

  create_table "lint_rules", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "rule"
    t.string "description"
  end

  create_table "organization_lint_rules", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "lint_rule_id"
    t.integer "severity"
    t.integer "organization_id"
    t.index ["lint_rule_id"], name: "index_organization_lint_rules_on_lint_rule_id"
    t.index ["organization_id"], name: "index_organization_lint_rules_on_organization_id"
  end

  create_table "organization_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_organization_users_on_organization_id"
    t.index ["user_id"], name: "index_organization_users_on_user_id"
  end

  create_table "organizations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "maximum_active_script_subscriptions"
  end

  create_table "performance_audit_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "performance_audit_id"
    t.text "logs", limit: 4294967295
    t.index ["performance_audit_id"], name: "index_performance_audit_logs_on_performance_audit_id"
  end

  create_table "performance_audit_preferences", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "script_subscriber_id"
    t.boolean "should_run_audit"
    t.string "url_to_audit"
    t.integer "num_test_iterations"
    t.index ["script_subscriber_id"], name: "index_performance_audit_preferences_on_script_subscriber_id"
  end

  create_table "performance_audits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.index ["audit_id"], name: "index_performance_audits_on_audit_id"
  end

  create_table "roles", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "roles_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id"], name: "index_roles_users_on_user_id"
  end

  create_table "script_changes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "script_id"
    t.integer "bytes"
    t.string "hashed_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "most_recent"
    t.index ["script_id"], name: "index_script_changes_on_script_id"
  end

  create_table "script_check_region", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "script_checks", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "script_id"
    t.integer "script_check_region_id"
    t.float "response_time_ms"
    t.integer "response_code"
    t.timestamp "created_at"
    t.index ["script_id"], name: "index_script_checks_on_script_id"
  end

  create_table "script_image_domain_lookup_patterns", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "script_image_id"
    t.string "url_pattern"
    t.index ["script_image_id"], name: "index_script_image_domain_lookup_patterns_on_script_image_id"
  end

  create_table "script_images", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "script_subscriber_allowed_performance_audit_tags", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "script_subscriber_id"
    t.string "url_pattern"
    t.index ["script_subscriber_id"], name: "index_allowed_performance_audit_tags_on_script_subscriber_id"
  end

  create_table "script_subscriber_lint_results", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "script_subscriber_id"
    t.integer "lint_result_id"
    t.index ["lint_result_id"], name: "index_script_subscriber_lint_results_on_lint_result_id"
    t.index ["script_subscriber_id"], name: "index_script_subscriber_lint_results_on_script_subscriber_id"
  end

  create_table "script_subscribers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "domain_id"
    t.bigint "script_id"
    t.boolean "active"
    t.string "friendly_name"
    t.timestamp "removed_from_site_at"
    t.boolean "monitor_changes"
    t.boolean "allowed_third_party_tag", default: false
    t.boolean "is_third_party_tag", default: true
    t.timestamp "created_at"
    t.integer "first_script_change_id"
    t.boolean "should_run_audit"
    t.integer "throttle_minute_threshold"
    t.integer "script_change_retention_count"
    t.integer "script_check_retention_count"
    t.boolean "consider_query_param_changes_new_tag"
    t.index ["domain_id"], name: "index_script_subscribers_on_domain_id"
    t.index ["script_id"], name: "index_script_subscribers_on_script_id"
  end

  create_table "script_test_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "scripts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "full_url"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.timestamp "content_changed_at"
    t.boolean "should_log_script_checks"
    t.integer "script_image_id"
    t.string "url_domain"
    t.string "url_path"
    t.text "url_query_param"
    t.index ["script_image_id"], name: "index_scripts_on_script_image_id"
    t.index ["url_domain"], name: "index_scripts_on_url_domain"
    t.index ["url_path"], name: "index_scripts_on_url_path"
  end

  create_table "slack_notification_subscribers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "script_subscriber_id"
    t.string "type"
    t.string "channel"
    t.index ["script_subscriber_id"], name: "index_slack_notification_subscribers_on_script_subscriber_id"
  end

  create_table "slack_settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "organization_id"
    t.string "access_token"
    t.string "app_id"
    t.string "team_id"
    t.string "team_name"
    t.index ["organization_id"], name: "index_slack_settings_on_organization_id"
  end

  create_table "test_runs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.boolean "passed"
    t.text "results", limit: 16777215
    t.timestamp "created_at"
    t.integer "script_test_type_id"
    t.integer "test_subscriber_id"
    t.integer "script_change_id"
    t.integer "test_group_run_id"
    t.integer "standalone_test_run_domain_id"
  end

  create_table "user_invites", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
end
