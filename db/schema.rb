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

ActiveRecord::Schema.define(version: 2022_03_03_181519) do

  create_table "active_storage_attachments", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb3", force: :cascade do |t|
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

  create_table "active_storage_variant_records", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audits", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.integer "execution_reason_id"
    t.boolean "primary"
    t.timestamp "created_at"
    t.boolean "throttled", default: false
    t.float "seconds_to_complete"
    t.integer "tag_version_id"
    t.integer "tag_id"
    t.datetime "deleted_at"
    t.string "performance_audit_error_message"
    t.integer "performance_audit_calculator_id"
    t.bigint "page_url_id"
    t.boolean "include_page_load_resources"
    t.boolean "include_page_change_audit"
    t.boolean "include_performance_audit"
    t.boolean "include_functional_tests"
    t.integer "num_functional_tests_to_run"
    t.timestamp "enqueued_suite_at"
    t.timestamp "performance_audit_completed_at"
    t.timestamp "page_change_audit_completed_at"
    t.timestamp "functional_tests_completed_at"
    t.float "tagsafe_score_confidence_range"
    t.integer "num_performance_audit_sets_ran"
    t.bigint "initiated_by_user_id"
    t.index ["execution_reason_id"], name: "index_audits_on_execution_reason_id"
    t.index ["initiated_by_user_id"], name: "index_audits_on_initiated_by_user_id"
    t.index ["page_url_id"], name: "index_audits_on_page_url_id"
    t.index ["performance_audit_calculator_id"], name: "index_audits_on_peformance_audit_calculator_id"
    t.index ["tag_id"], name: "index_audits_on_tag_id"
    t.index ["tag_version_id"], name: "index_audits_on_tag_version_id"
    t.index ["uid"], name: "index_audits_on_uid"
  end

  create_table "blocked_resources", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.bigint "performance_audit_id"
    t.text "url"
    t.string "resource_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["performance_audit_id"], name: "index_blocked_resources_on_performance_audit_id"
  end

  create_table "default_audit_configurations", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "parent_type"
    t.bigint "parent_id"
    t.boolean "include_performance_audit"
    t.boolean "include_page_load_resources"
    t.boolean "include_page_change_audit"
    t.boolean "include_functional_tests"
    t.integer "num_functional_tests_to_run"
    t.integer "num_perf_audits_to_run"
    t.boolean "perf_audit_strip_all_images"
    t.boolean "perf_audit_include_page_tracing"
    t.boolean "perf_audit_throw_error_if_dom_complete_is_zero"
    t.boolean "perf_audit_inline_injected_script_tags"
    t.boolean "perf_audit_scroll_page"
    t.boolean "perf_audit_enable_screen_recording"
    t.boolean "perf_audit_override_initial_html_request_with_manipulated_page"
    t.string "perf_audit_completion_indicator_type"
    t.float "perf_audit_required_tagsafe_score_range"
    t.index ["parent_type", "parent_id"], name: "index_default_audit_configuration_on_parent"
    t.index ["uid"], name: "index_default_audit_configurations_on_uid"
  end

  create_table "delta_performance_audits", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "type"
    t.bigint "audit_id"
    t.bigint "performance_audit_with_tag_id"
    t.bigint "performance_audit_without_tag_id"
    t.float "dom_complete_delta"
    t.float "dom_content_loaded_delta"
    t.float "dom_interactive_delta"
    t.float "first_contentful_paint_delta"
    t.float "script_duration_delta"
    t.float "layout_duration_delta"
    t.float "task_duration_delta"
    t.float "tagsafe_score"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_outlier"
    t.index ["audit_id"], name: "index_delta_performance_audits_on_audit_id"
    t.index ["performance_audit_with_tag_id"], name: "index_dpa_performance_audit_with_tag_id"
    t.index ["performance_audit_without_tag_id"], name: "index_dpa_performance_audit_without_tag_id"
    t.index ["uid"], name: "index_delta_performance_audits_on_uid"
  end

  create_table "domains", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.integer "organization_id"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.integer "current_performance_audit_calculator_id"
    t.index ["current_performance_audit_calculator_id"], name: "index_domains_on_current_performance_audit_calculator_id"
    t.index ["organization_id"], name: "index_domains_on_organization_id"
    t.index ["uid"], name: "index_domains_on_uid"
    t.index ["url"], name: "index_domains_on_url"
  end

  create_table "email_notification_subscribers", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid", null: false
    t.string "type"
    t.integer "user_id"
    t.integer "tag_id"
    t.index ["tag_id"], name: "index_email_notification_subscribers_on_tag_id"
    t.index ["uid"], name: "index_email_notification_subscribers_on_uid"
    t.index ["user_id"], name: "index_email_notification_subscribers_on_user_id"
  end

  create_table "events", charset: "utf8mb3", force: :cascade do |t|
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.text "metadata"
    t.string "uid"
    t.datetime "deleted_at"
    t.bigint "triggerer_id"
    t.string "triggerer_type"
    t.index ["triggerer_id"], name: "index_events_on_triggerer_id"
  end

  create_table "executed_lambda_functions", charset: "utf8mb3", force: :cascade do |t|
    t.string "parent_type"
    t.bigint "parent_id"
    t.string "function_name"
    t.text "request_payload"
    t.text "response_payload", size: :long
    t.integer "response_code"
    t.string "uid"
    t.string "aws_log_stream_name"
    t.string "aws_request_id"
    t.string "aws_trace_id"
    t.datetime "executed_at"
    t.datetime "completed_at"
    t.index ["parent_type", "parent_id"], name: "index_executed_lambda_functions_on_parent"
  end

  create_table "execution_reasons", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.index ["uid"], name: "index_execution_reasons_on_uid"
  end

  create_table "filmstrip_screenshots", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "performance_audit_id"
    t.string "uid"
    t.integer "timestamp"
    t.index ["performance_audit_id"], name: "index_filmstrip_screenshots_on_performance_audit_id"
    t.index ["uid"], name: "index_filmstrip_screenshots_on_uid"
  end

  create_table "flags", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.string "slug"
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "default_value"
  end

  create_table "functional_tests", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.bigint "domain_id"
    t.bigint "created_by_user_id"
    t.string "title"
    t.string "description"
    t.text "puppeteer_script"
    t.string "expected_results"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "run_on_all_tags"
    t.boolean "passed_dry_run"
    t.timestamp "disabled_at"
    t.index ["created_by_user_id"], name: "index_functional_tests_on_created_by_user_id"
    t.index ["domain_id"], name: "index_functional_tests_on_domain_id"
    t.index ["uid"], name: "index_functional_tests_on_uid"
  end

  create_table "functional_tests_to_run", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "tag_id"
    t.bigint "functional_test_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "uid"
    t.index ["functional_test_id"], name: "index_functional_tests_to_run_on_functional_test_id"
    t.index ["tag_id"], name: "index_functional_tests_to_run_on_tag_id"
    t.index ["uid"], name: "index_functional_tests_to_run_on_uid"
  end

  create_table "html_snapshots", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "type"
    t.string "html_s3_location"
    t.timestamp "enqueued_at"
    t.timestamp "completed_at"
    t.bigint "page_change_audit_id"
    t.string "screenshot_s3_location"
    t.index ["page_change_audit_id"], name: "index_html_snapshots_on_page_change_audit_id"
    t.index ["uid"], name: "index_html_snapshots_on_uid"
  end

  create_table "monitored_scripts", charset: "utf8mb3", force: :cascade do |t|
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.timestamp "script_last_updated_at"
  end

  create_table "non_third_party_url_patterns", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.integer "domain_id"
    t.string "pattern"
    t.index ["domain_id"], name: "index_non_third_party_url_patterns_on_domain_id"
    t.index ["uid"], name: "index_non_third_party_url_patterns_on_uid"
  end

  create_table "notification_subscribers", charset: "utf8mb3", force: :cascade do |t|
    t.integer "monitored_script_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "object_flags", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "object_type"
    t.bigint "object_id"
    t.bigint "flag_id"
    t.string "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["flag_id"], name: "index_object_flags_on_flag_id"
    t.index ["object_type", "object_id"], name: "index_object_flags_on_object"
  end

  create_table "organization_users", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.integer "user_id"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_organization_users_on_organization_id"
    t.index ["uid"], name: "index_organization_users_on_uid"
    t.index ["user_id"], name: "index_organization_users_on_user_id"
  end

  create_table "organizations", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tag_version_retention_count"
    t.integer "tag_check_retention_count"
    t.datetime "deleted_at"
    t.index ["uid"], name: "index_organizations_on_uid"
  end

  create_table "page_change_audits", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.bigint "audit_id"
    t.boolean "tag_causes_page_changes"
    t.integer "num_additions_between_without_tag_snapshots"
    t.integer "num_deletions_between_without_tag_snapshots"
    t.integer "num_additions_between_with_tag_snapshot_without_tag_snapshot"
    t.integer "num_deletions_between_with_tag_snapshot_without_tag_snapshot"
    t.string "initial_html_content_s3_url"
    t.string "error_message"
    t.index ["audit_id"], name: "index_page_change_audits_on_audit_id"
    t.index ["uid"], name: "index_page_change_audits_on_uid"
  end

  create_table "page_load_resources", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "performance_audit_id"
    t.text "name"
    t.string "entry_type"
    t.float "fetch_start"
    t.float "response_end"
    t.float "duration"
    t.string "uid"
    t.string "initiator_type"
    t.index ["performance_audit_id"], name: "index_page_load_resources_on_performance_audit_id"
  end

  create_table "page_load_screenshots", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "performance_audit_id"
    t.string "s3_url"
    t.integer "timestamp_ms"
    t.string "uid"
    t.integer "sequence"
    t.index ["performance_audit_id"], name: "index_page_load_screenshots_on_performance_audit_id"
    t.index ["uid"], name: "index_page_load_screenshots_on_uid"
  end

  create_table "page_load_traces", charset: "utf8mb3", force: :cascade do |t|
    t.string "s3_url"
    t.bigint "performance_audit_id"
    t.string "uid"
    t.index ["performance_audit_id"], name: "index_page_load_traces_on_performance_audit_id"
  end

  create_table "page_urls", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "domain_id"
    t.string "full_url"
    t.string "hostname"
    t.string "pathname"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "uid"
    t.boolean "should_scan_for_tags"
    t.string "screenshot_s3_url"
    t.index ["domain_id"], name: "index_page_urls_on_domain_id"
    t.index ["full_url"], name: "index_page_urls_on_full_url"
    t.index ["hostname"], name: "index_page_urls_on_hostname"
    t.index ["pathname"], name: "index_page_urls_on_pathname"
    t.index ["uid"], name: "index_page_urls_on_uid"
  end

  create_table "performance_audit_calculators", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.bigint "domain_id"
    t.boolean "currently_active"
    t.float "dom_complete_weight"
    t.float "dom_content_loaded_weight"
    t.float "dom_interactive_weight"
    t.float "first_contentful_paint_weight"
    t.float "layout_duration_weight"
    t.float "task_duration_weight"
    t.float "script_duration_weight"
    t.float "byte_size_weight"
    t.integer "dom_complete_score_decrement_amount"
    t.integer "dom_content_loaded_score_decrement_amount"
    t.integer "dom_interactive_score_decrement_amount"
    t.integer "first_contentful_paint_score_decrement_amount"
    t.integer "layout_duration_score_decrement_amount"
    t.integer "task_duration_score_decrement_amount"
    t.integer "script_duration_score_decrement_amount"
    t.integer "byte_size_score_decrement_amount"
    t.index ["domain_id"], name: "index_performance_audit_calculators_on_domain_id"
  end

  create_table "performance_audit_configurations", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "audit_id"
    t.integer "num_performance_audits_to_run"
    t.boolean "strip_all_images"
    t.boolean "include_page_tracing"
    t.boolean "throw_error_if_dom_complete_is_zero"
    t.boolean "inline_injected_script_tags"
    t.string "uid"
    t.boolean "scroll_page"
    t.boolean "enable_screen_recording"
    t.boolean "override_initial_html_request_with_manipulated_page"
    t.string "cached_responses_s3_url"
    t.string "completion_indicator_type"
    t.float "required_tagsafe_score_range"
    t.index ["audit_id"], name: "index_performance_audit_configurations_on_audit_id"
    t.index ["uid"], name: "index_performance_audit_configurations_on_uid"
  end

  create_table "performance_audit_logs", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid", null: false
    t.integer "performance_audit_id"
    t.text "logs", size: :long
    t.index ["performance_audit_id"], name: "index_performance_audit_logs_on_performance_audit_id"
    t.index ["uid"], name: "index_performance_audit_logs_on_uid"
  end

  create_table "performance_audits", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid", null: false
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
    t.timestamp "completed_at"
    t.text "error_message"
    t.float "seconds_to_complete"
    t.datetime "deleted_at"
    t.float "dom_content_loaded"
    t.string "page_trace_s3_url"
    t.boolean "audit_performed_with_tag"
    t.index ["audit_id"], name: "index_performance_audit_averages_on_audit_id"
    t.index ["uid"], name: "index_performance_audits_on_uid"
  end

  create_table "puppeteer_recordings", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "initiator_type"
    t.bigint "initiator_id"
    t.string "s3_url"
    t.integer "ms_to_stop_recording"
    t.datetime "created_at", null: false
    t.integer "ms_available_to_stop_within"
    t.index ["initiator_type", "initiator_id"], name: "index_puppeteer_recordings_on_initiator"
    t.index ["uid"], name: "index_puppeteer_recordings_on_uid"
  end

  create_table "roles", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.index ["uid"], name: "index_roles_on_uid"
  end

  create_table "roles_users", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid", null: false
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["uid"], name: "index_roles_users_on_uid"
    t.index ["user_id"], name: "index_roles_users_on_user_id"
  end

  create_table "scripts", charset: "utf8mb3", force: :cascade do |t|
    t.string "url"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_scripts_on_url"
  end

  create_table "slack_notification_subscribers", charset: "utf8mb3", force: :cascade do |t|
    t.string "type"
    t.string "channel"
    t.bigint "tag_id"
    t.index ["tag_id"], name: "index_slack_notification_subscribers_on_tag_id"
  end

  create_table "slack_settings", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.integer "organization_id"
    t.string "access_token"
    t.integer "app_id"
    t.integer "team_id"
    t.string "team_name"
    t.index ["organization_id"], name: "index_slack_settings_on_organization_id"
    t.index ["uid"], name: "index_slack_settings_on_uid"
  end

  create_table "tag_allowed_performance_audit_third_party_urls", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "url_pattern"
    t.integer "tag_id"
    t.index ["tag_id"], name: "index_tag_allowed_performance_audit_third_party_urls_on_tag_id"
    t.index ["uid"], name: "index_tag_allowed_performance_audit_third_party_urls_on_uid"
  end

  create_table "tag_check_region", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
  end

  create_table "tag_checks", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.float "response_time_ms"
    t.integer "response_code"
    t.timestamp "created_at"
    t.integer "tag_id"
    t.integer "tag_check_region_id"
    t.boolean "content_has_detectable_changes"
    t.boolean "content_is_the_same_as_a_previous_version"
    t.boolean "bytesize_changed"
    t.boolean "hash_changed"
    t.index ["tag_check_region_id"], name: "index_tag_checks_on_tag_check_region_id"
    t.index ["tag_id"], name: "index_tag_checks_on_tag_id"
    t.index ["uid"], name: "index_tag_checks_on_uid"
  end

  create_table "tag_identifying_data", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.string "company"
    t.string "homepage"
    t.string "category"
    t.index ["uid"], name: "index_tag_identifying_data_on_uid"
  end

  create_table "tag_identifying_data_domains", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.bigint "tag_identifying_data_id"
    t.string "url_pattern"
    t.index ["tag_identifying_data_id"], name: "index_tag_identifying_data_domains_on_tag_identifying_data_id"
    t.index ["uid"], name: "index_tag_identifying_data_domains_on_uid"
    t.index ["url_pattern"], name: "index_tag_identifying_data_domains_on_url_pattern"
  end

  create_table "tag_preferences", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "url_to_audit"
    t.integer "tag_id"
    t.boolean "enabled"
    t.boolean "is_allowed_third_party_tag"
    t.boolean "is_third_party_tag"
    t.boolean "should_log_tag_checks"
    t.boolean "consider_query_param_changes_new_tag"
    t.integer "throttle_minute_threshold"
    t.datetime "deleted_at"
    t.index ["tag_id"], name: "index_tag_preferences_on_tag_id"
    t.index ["uid"], name: "index_tag_preferences_on_uid"
  end

  create_table "tag_versions", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.integer "bytes"
    t.string "hashed_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "most_recent"
    t.integer "tag_id"
    t.datetime "deleted_at"
    t.bigint "tag_check_captured_with_id"
    t.index ["tag_check_captured_with_id"], name: "index_tag_versions_on_tag_check_captured_with_id"
    t.index ["tag_id"], name: "index_tag_versions_on_tag_id"
    t.index ["uid"], name: "index_tag_versions_on_uid"
  end

  create_table "tags", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.integer "domain_id"
    t.string "friendly_name"
    t.timestamp "removed_from_site_at"
    t.timestamp "created_at"
    t.text "full_url"
    t.string "url_domain"
    t.string "url_path"
    t.text "url_query_param"
    t.timestamp "content_changed_at"
    t.integer "tag_image_id"
    t.string "load_type"
    t.datetime "deleted_at"
    t.bigint "found_on_page_url_id"
    t.bigint "found_on_url_crawl_id"
    t.bigint "tag_identifying_data_id"
    t.boolean "has_content"
    t.index ["domain_id"], name: "index_tags_on_domain_id"
    t.index ["found_on_page_url_id"], name: "index_tags_on_found_on_page_url_id"
    t.index ["found_on_url_crawl_id"], name: "index_tags_on_found_on_url_crawl_id"
    t.index ["tag_identifying_data_id"], name: "index_tags_on_tag_identifying_data_id"
    t.index ["tag_image_id"], name: "index_tags_on_tag_image_id"
    t.index ["uid"], name: "index_tags_on_uid"
  end

  create_table "test_run_screenshots", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.bigint "test_run_id"
    t.string "name"
    t.string "s3_url"
    t.integer "timestamp"
    t.index ["test_run_id"], name: "index_test_run_screenshots_on_test_run_id"
    t.index ["uid"], name: "index_test_run_screenshots_on_uid"
  end

  create_table "test_runs", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.bigint "functional_test_id"
    t.bigint "audit_id"
    t.string "type"
    t.string "results"
    t.boolean "passed"
    t.timestamp "enqueued_at"
    t.timestamp "completed_at"
    t.text "logs", size: :medium
    t.text "puppeteer_script_ran"
    t.string "expected_results"
    t.bigint "original_test_run_with_tag_id"
    t.integer "test_run_id_retried_from"
    t.string "error_message"
    t.string "error_type"
    t.text "error_trace"
    t.integer "script_execution_ms"
    t.index ["audit_id"], name: "index_test_runs_on_audit_id"
    t.index ["functional_test_id"], name: "index_test_runs_on_functional_test_id"
    t.index ["original_test_run_with_tag_id"], name: "index_test_runs_on_original_test_run_with_tag_id"
    t.index ["test_run_id_retried_from"], name: "index_test_runs_on_test_run_id_retried_from"
    t.index ["uid"], name: "index_test_runs_on_uid"
  end

  create_table "url_crawl_retrieved_urls", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.bigint "url_crawl_id"
    t.text "url"
    t.index ["uid"], name: "index_url_crawl_retrieved_urls_on_uid"
    t.index ["url_crawl_id"], name: "index_url_crawl_retrieved_urls_on_url_crawl_id"
  end

  create_table "url_crawls", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.integer "domain_id"
    t.datetime "enqueued_at"
    t.datetime "completed_at"
    t.text "error_message"
    t.string "url"
    t.float "seconds_to_complete"
    t.datetime "deleted_at"
    t.bigint "page_url_id"
    t.integer "num_first_party_bytes"
    t.integer "num_third_party_bytes"
    t.index ["domain_id"], name: "index_url_crawls_on_domain_id"
    t.index ["page_url_id"], name: "index_url_crawls_on_page_url_id"
    t.index ["uid"], name: "index_url_crawls_on_uid"
  end

  create_table "urls_to_audit", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "tag_id"
    t.boolean "primary"
    t.string "uid"
    t.bigint "page_url_id"
    t.index ["page_url_id"], name: "index_urls_to_audit_on_page_url_id"
    t.index ["tag_id"], name: "index_urls_to_audit_on_tag_id"
  end

  create_table "urls_to_audits", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "tags_id"
    t.string "url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["tags_id"], name: "index_urls_to_audits_on_tags_id"
  end

  create_table "urls_to_crawl", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.integer "domain_id"
    t.string "url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["domain_id"], name: "index_urls_to_crawl_on_domain_id"
    t.index ["uid"], name: "index_urls_to_crawl_on_uid"
  end

  create_table "user_invites", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.integer "organization_id"
    t.string "email"
    t.string "token"
    t.timestamp "expires_at"
    t.timestamp "created_at"
    t.integer "invited_by_user_id"
    t.timestamp "redeemed_at"
    t.index ["invited_by_user_id"], name: "index_user_invites_on_invited_by_user_id"
    t.index ["organization_id"], name: "index_user_invites_on_organization_id"
    t.index ["uid"], name: "index_user_invites_on_uid"
  end

  create_table "user_roles", charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "uid"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "deleted_at"
    t.index ["uid"], name: "index_users_on_uid"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
