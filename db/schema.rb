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

ActiveRecord::Schema.define(version: 2020_12_07_025029) do

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
    t.timestamp "performance_audit_completed_at"
    t.timestamp "test_suite_enqueued_at"
    t.timestamp "test_suite_completed_at"
    t.string "performance_audit_url"
    t.timestamp "created_at"
    t.string "performance_audit_error_message"
  end

  create_table "domains", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "organization_id"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_domains_on_organization_id"
    t.index ["url"], name: "index_domains_on_url"
  end

  create_table "execution_reasons", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "expected_test_results", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "expected_result"
    t.string "operator"
    t.string "data_type"
  end

  create_table "notification_subscribers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "type"
    t.integer "user_id"
    t.integer "script_subscriber_id"
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
  end

  create_table "performance_audit_metric_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.string "key"
    t.text "description"
    t.string "unit"
  end

  create_table "performance_audit_metrics", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "performance_audit_id"
    t.integer "performance_audit_metric_type_id"
    t.float "result"
  end

  create_table "performance_audit_preferences", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "script_subscriber_id"
    t.boolean "should_run_audit"
    t.string "url_to_audit"
    t.integer "num_test_iterations"
  end

  create_table "performance_audits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "audit_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "roles_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
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
  end

  create_table "script_image_domain_lookup_patterns", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "script_image_id"
    t.string "url_pattern"
  end

  create_table "script_images", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["domain_id"], name: "index_script_subscribers_on_domain_id"
    t.index ["script_id"], name: "index_script_subscribers_on_script_id"
  end

  create_table "script_test_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "scripts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "url"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.timestamp "content_changed_at"
    t.boolean "should_log_script_checks"
    t.integer "script_image_id"
  end

  create_table "test_group_runs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "test_subscriber_id"
    t.bigint "script_change_id"
    t.boolean "passed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "execution_reason_id"
    t.timestamp "enqueued_at"
    t.timestamp "completed_at"
    t.index ["script_change_id"], name: "index_test_group_runs_on_script_change_id"
    t.index ["test_subscriber_id"], name: "index_test_group_runs_on_test_subscriber_id"
  end

  create_table "test_result_subscribers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "test_id"
    t.index ["test_id"], name: "index_test_result_subscribers_on_test_id"
    t.index ["user_id"], name: "index_test_result_subscribers_on_user_id"
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

  create_table "test_subscribers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "test_id"
    t.integer "script_subscriber_id"
    t.integer "expected_test_result_id"
    t.boolean "active"
    t.index ["test_id"], name: "index_test_subscribers_on_test_id"
  end

  create_table "tests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "test_script", limit: 16777215
    t.boolean "default_test", default: false
    t.integer "created_by_organization_id"
    t.string "title"
    t.string "description"
    t.integer "created_by_user_id"
  end

  create_table "user_invites", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "organization_id"
    t.string "email"
    t.string "token"
    t.timestamp "expires_at"
    t.timestamp "created_at"
    t.integer "invited_by_user_id"
    t.timestamp "redeemed_at"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "organization_id"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
end
