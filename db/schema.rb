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

ActiveRecord::Schema.define(version: 2023_01_02_234650) do

  create_table "active_storage_attachments", charset: "utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
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

  create_table "alert_configuration_container_users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid"
    t.bigint "container_user_id"
    t.bigint "alert_configuration_id"
    t.index ["alert_configuration_id"], name: "index_alert_configuration_domain_users_on_alert_configuration_id"
    t.index ["container_user_id"], name: "index_alert_configuration_domain_users_on_domain_user_id"
    t.index ["uid"], name: "index_alert_configuration_domain_users_on_uid"
  end

  create_table "alert_configuration_tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid"
    t.bigint "tag_id"
    t.bigint "alert_configuration_id"
    t.index ["alert_configuration_id"], name: "index_alert_configuration_tags_on_alert_configuration_id"
    t.index ["tag_id"], name: "index_alert_configuration_tags_on_tag_id"
    t.index ["uid"], name: "index_alert_configuration_tags_on_uid"
  end

  create_table "alert_configurations", primary_key: "container_user_id", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.bigint "container_id"
    t.string "name"
    t.string "type"
    t.string "trigger_rules"
    t.boolean "enabled_for_all_tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.index ["container_id"], name: "index_alert_configurations_on_container_id"
    t.index ["uid"], name: "index_alert_configurations_on_uid"
  end

  create_table "audit_components", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid"
    t.string "type"
    t.bigint "audit_id"
    t.float "score"
    t.float "score_weight"
    t.text "raw_results"
    t.timestamp "started_at"
    t.timestamp "completed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.timestamp "lambda_response_received_at"
    t.string "error_message"
    t.index ["audit_id"], name: "index_audit_components_on_audit_id"
    t.index ["uid"], name: "index_audit_components_on_uid"
  end

  create_table "audits", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid"
    t.bigint "container_id"
    t.bigint "tag_id"
    t.bigint "tag_version_id"
    t.bigint "page_url_id"
    t.bigint "initiated_by_container_user_id"
    t.float "tagsafe_score"
    t.timestamp "started_at"
    t.timestamp "completed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "execution_reason_id"
    t.string "error_message"
    t.index ["container_id"], name: "index_audits_on_container_id"
    t.index ["execution_reason_id"], name: "index_audits_on_execution_reason_id"
    t.index ["initiated_by_container_user_id"], name: "index_audits_on_initiated_by_container_user_id"
    t.index ["page_url_id"], name: "index_audits_on_page_url_id"
    t.index ["tag_id"], name: "index_audits_on_tag_id"
    t.index ["tag_version_id"], name: "index_audits_on_tag_version_id"
    t.index ["uid"], name: "index_audits_on_uid"
  end

  create_table "aws_event_bridge_rules", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.boolean "enabled"
    t.string "type"
    t.string "region"
    t.index ["uid"], name: "index_aws_event_bridge_rules_on_uid"
  end

  create_table "blocked_resources", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.bigint "performance_audit_id"
    t.text "url"
    t.string "resource_type"
    t.index ["performance_audit_id"], name: "index_blocked_resources_on_performance_audit_id"
    t.index ["uid"], name: "index_blocked_resources_on_uid"
  end

  create_table "container_users", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.integer "user_id"
    t.integer "container_id"
    t.index ["container_id"], name: "index_container_users_on_container_id"
    t.index ["uid"], name: "index_container_users_on_uid"
    t.index ["user_id"], name: "index_container_users_on_user_id"
  end

  create_table "container_users_roles", charset: "utf8", force: :cascade do |t|
    t.string "uid", null: false
    t.integer "container_user_id"
    t.integer "role_id"
    t.index ["container_user_id"], name: "index_container_users_roles_on_container_user_id"
    t.index ["role_id"], name: "index_container_users_roles_on_role_id"
    t.index ["uid"], name: "index_container_users_roles_on_uid"
  end

  create_table "containers", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "instrumentation_key"
    t.float "tagsafe_js_reporting_sample_rate"
    t.boolean "tagsafe_js_enabled"
    t.index ["name"], name: "index_containers_on_name"
    t.index ["uid"], name: "index_containers_on_uid"
  end

  create_table "delta_performance_audits", charset: "utf8", force: :cascade do |t|
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
    t.integer "bytes"
    t.float "main_thread_execution_tag_responsible_for_delta"
    t.float "speed_index_delta"
    t.float "perceptual_speed_index_delta"
    t.float "ms_until_first_visual_change_delta"
    t.float "ms_until_last_visual_change_delta"
    t.float "main_thread_blocking_execution_tag_responsible_for_delta"
    t.float "entire_main_thread_execution_ms_delta"
    t.float "entire_main_thread_blocking_executions_ms_delta"
    t.index ["audit_id"], name: "index_delta_performance_audits_on_audit_id"
    t.index ["performance_audit_with_tag_id"], name: "index_dpa_performance_audit_with_tag_id"
    t.index ["performance_audit_without_tag_id"], name: "index_dpa_performance_audit_without_tag_id"
    t.index ["uid"], name: "index_delta_performance_audits_on_uid"
  end

  create_table "email_notification_subscribers", charset: "utf8", force: :cascade do |t|
    t.string "uid", null: false
    t.string "type"
    t.integer "user_id"
    t.integer "tag_id"
    t.index ["tag_id"], name: "index_email_notification_subscribers_on_tag_id"
    t.index ["uid"], name: "index_email_notification_subscribers_on_uid"
    t.index ["user_id"], name: "index_email_notification_subscribers_on_user_id"
  end

  create_table "events", charset: "utf8", force: :cascade do |t|
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.text "metadata"
    t.string "uid"
    t.datetime "deleted_at"
    t.bigint "triggerer_id"
    t.string "triggerer_type"
    t.index ["triggerer_id"], name: "index_events_on_triggerer_id"
    t.index ["uid"], name: "index_events_on_uid"
  end

  create_table "executed_step_functions", charset: "utf8", force: :cascade do |t|
    t.string "parent_type"
    t.bigint "parent_id"
    t.text "request_payload"
    t.text "response_payload", size: :long
    t.integer "response_code"
    t.string "uid"
    t.string "aws_log_stream_name"
    t.string "aws_request_id"
    t.string "aws_trace_id"
    t.datetime "executed_at"
    t.datetime "completed_at"
    t.float "ms_to_receive_response"
    t.string "step_function_execution_arn"
    t.string "step_function_execution_name"
    t.text "error_message"
    t.index ["parent_type", "parent_id"], name: "index_executed_lambda_functions_on_parent"
    t.index ["uid"], name: "index_executed_step_functions_on_uid"
  end

  create_table "execution_reasons", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.index ["uid"], name: "index_execution_reasons_on_uid"
  end

  create_table "functional_tests", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.bigint "container_id"
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
    t.index ["container_id"], name: "index_functional_tests_on_container_id"
    t.index ["created_by_user_id"], name: "index_functional_tests_on_created_by_user_id"
    t.index ["uid"], name: "index_functional_tests_on_uid"
  end

  create_table "functional_tests_to_run", charset: "utf8", force: :cascade do |t|
    t.bigint "tag_id"
    t.bigint "functional_test_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "uid"
    t.index ["functional_test_id"], name: "index_functional_tests_to_run_on_functional_test_id"
    t.index ["tag_id"], name: "index_functional_tests_to_run_on_tag_id"
    t.index ["uid"], name: "index_functional_tests_to_run_on_uid"
  end

  create_table "general_configurations", charset: "utf8", force: :cascade do |t|
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
    t.boolean "enable_monitoring_on_new_tags"
    t.integer "perf_audit_minimum_num_sets"
    t.integer "perf_audit_maximum_num_sets"
    t.boolean "perf_audit_fail_when_confidence_range_not_met"
    t.integer "perf_audit_batch_size"
    t.integer "perf_audit_max_failures"
    t.boolean "roll_up_audits_by_tag_version"
    t.integer "num_recent_tag_versions_to_compare_in_release_monitoring"
    t.boolean "perf_audit_include_filmstrip_frames"
    t.index ["parent_type", "parent_id"], name: "index_default_audit_configuration_on_parent"
    t.index ["uid"], name: "index_general_configurations_on_uid"
  end

  create_table "instrumentation_builds", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid"
    t.bigint "container_id"
    t.text "description", size: :medium
    t.datetime "created_at", null: false
    t.index ["container_id"], name: "index_instrumentation_builds_on_container_id"
    t.index ["uid"], name: "index_instrumentation_builds_on_uid"
  end

  create_table "legacy_audits", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.integer "execution_reason_id"
    t.boolean "primary"
    t.timestamp "created_at"
    t.boolean "throttled", default: false
    t.float "seconds_to_complete"
    t.integer "tag_version_id"
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
    t.bigint "initiated_by_container_user_id"
    t.boolean "has_confident_tagsafe_score"
    t.boolean "tagsafe_score_is_confident"
    t.bigint "container_id"
    t.bigint "tag_id"
    t.index ["container_id"], name: "index_legacy_audits_on_container_id"
    t.index ["execution_reason_id"], name: "index_legacy_audits_on_execution_reason_id"
    t.index ["initiated_by_container_user_id"], name: "index_legacy_audits_on_initiated_by_container_user_id"
    t.index ["page_url_id"], name: "index_legacy_audits_on_page_url_id"
    t.index ["performance_audit_calculator_id"], name: "index_audits_on_peformance_audit_calculator_id"
    t.index ["tag_id"], name: "index_legacy_audits_on_tag_id"
    t.index ["tag_version_id"], name: "index_legacy_audits_on_tag_version_id"
    t.index ["uid"], name: "index_legacy_audits_on_uid"
  end

  create_table "non_third_party_url_patterns", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.integer "container_id"
    t.string "pattern"
    t.index ["container_id"], name: "index_non_third_party_url_patterns_on_container_id"
    t.index ["uid"], name: "index_non_third_party_url_patterns_on_uid"
  end

  create_table "page_load_performance_metrics", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid"
    t.bigint "container_id"
    t.bigint "page_load_id"
    t.string "type"
    t.float "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "page_url_id"
    t.index ["container_id"], name: "index_page_load_performance_metrics_on_container_id"
    t.index ["page_load_id"], name: "index_page_load_performance_metrics_on_page_load_id"
    t.index ["page_url_id"], name: "index_page_load_performance_metrics_on_page_url_id"
    t.index ["uid"], name: "index_page_load_performance_metrics_on_uid"
  end

  create_table "page_load_resources", charset: "utf8", force: :cascade do |t|
    t.bigint "performance_audit_id"
    t.text "name"
    t.string "entry_type"
    t.float "fetch_start"
    t.float "response_end"
    t.float "duration"
    t.string "uid"
    t.string "initiator_type"
    t.index ["performance_audit_id"], name: "index_page_load_resources_on_performance_audit_id"
    t.index ["uid"], name: "index_page_load_resources_on_uid"
  end

  create_table "page_load_traces", charset: "utf8", force: :cascade do |t|
    t.string "s3_url"
    t.bigint "performance_audit_id"
    t.string "uid"
    t.index ["performance_audit_id"], name: "index_page_load_traces_on_performance_audit_id"
    t.index ["uid"], name: "index_page_load_traces_on_uid"
  end

  create_table "page_loads", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid"
    t.string "page_load_identifier"
    t.bigint "container_id"
    t.bigint "page_url_id"
    t.string "cloudflare_message_id"
    t.float "seconds_to_complete"
    t.timestamp "page_load_ts"
    t.timestamp "enqueued_at"
    t.timestamp "tagsafe_consumer_received_at"
    t.timestamp "tagsafe_consumer_processed_at"
    t.integer "num_tags_optimized_by_tagsafe_js"
    t.integer "num_tags_not_optimized_by_tagsafe_js"
    t.index ["container_id"], name: "index_page_loads_on_container_id"
    t.index ["page_load_identifier"], name: "index_page_loads_on_page_load_identifier"
    t.index ["page_url_id"], name: "index_page_loads_on_page_url_id"
    t.index ["uid"], name: "index_page_loads_on_uid"
  end

  create_table "page_urls", charset: "utf8", force: :cascade do |t|
    t.bigint "container_id"
    t.string "full_url"
    t.string "hostname"
    t.string "pathname"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "uid"
    t.boolean "should_scan_for_tags"
    t.string "screenshot_s3_url"
    t.index ["container_id"], name: "index_page_urls_on_container_id"
    t.index ["full_url"], name: "index_page_urls_on_full_url"
    t.index ["hostname"], name: "index_page_urls_on_hostname"
    t.index ["pathname"], name: "index_page_urls_on_pathname"
    t.index ["uid"], name: "index_page_urls_on_uid"
  end

  create_table "page_urls_tag_found_on", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "tag_id"
    t.bigint "page_url_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.timestamp "last_seen_at"
    t.string "uid"
    t.boolean "should_audit"
    t.index ["page_url_id"], name: "index_page_urls_tag_found_on_on_page_url_id"
    t.index ["tag_id"], name: "index_page_urls_tag_found_on_on_tag_id"
  end

  create_table "performance_audit_calculators", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.bigint "container_id"
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
    t.float "main_thread_execution_tag_responsible_for_weight"
    t.float "speed_index_weight"
    t.float "perceptual_speed_index_weight"
    t.float "ms_until_first_visual_change_weight"
    t.float "ms_until_last_visual_change_weight"
    t.float "main_thread_execution_tag_responsible_for_score_decrement_amount"
    t.float "speed_index_score_decrement_amount"
    t.float "perceptual_speed_index_score_decrement_amount"
    t.float "ms_until_first_visual_change_score_decrement_amount"
    t.float "ms_until_last_visual_change_score_decrement_amount"
    t.index ["container_id"], name: "index_performance_audit_calculators_on_container_id"
    t.index ["uid"], name: "index_performance_audit_calculators_on_uid"
  end

  create_table "performance_audit_configurations", charset: "utf8", force: :cascade do |t|
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
    t.integer "minimum_num_sets"
    t.integer "maximum_num_sets"
    t.boolean "fail_when_confidence_range_not_met"
    t.integer "batch_size"
    t.integer "max_failures"
    t.boolean "include_filmstrip_frames"
    t.index ["audit_id"], name: "index_performance_audit_configurations_on_audit_id"
    t.index ["uid"], name: "index_performance_audit_configurations_on_uid"
  end

  create_table "performance_audit_logs", charset: "utf8", force: :cascade do |t|
    t.string "uid", null: false
    t.integer "performance_audit_id"
    t.text "logs", size: :long
    t.index ["performance_audit_id"], name: "index_performance_audit_logs_on_performance_audit_id"
    t.index ["uid"], name: "index_performance_audit_logs_on_uid"
  end

  create_table "performance_audit_speed_index_frames", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.bigint "performance_audit_id"
    t.string "s3_url"
    t.float "ms_from_start"
    t.float "ts"
    t.float "progress"
    t.float "perceptual_progress"
    t.index ["performance_audit_id"], name: "index_pasif_on_performance_audit_id"
    t.index ["uid"], name: "index_performance_audit_speed_index_frames_on_uid"
  end

  create_table "performance_audits", charset: "utf8", force: :cascade do |t|
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
    t.string "batch_identifier"
    t.datetime "lambda_response_received_at"
    t.integer "bytes"
    t.float "main_thread_execution_tag_responsible_for"
    t.float "speed_index"
    t.float "perceptual_speed_index"
    t.float "ms_until_first_visual_change"
    t.float "ms_until_last_visual_change"
    t.float "main_thread_blocking_execution_tag_responsible_for"
    t.float "entire_main_thread_execution_ms"
    t.float "entire_main_thread_blocking_executions_ms"
    t.index ["audit_id"], name: "index_performance_audit_averages_on_audit_id"
    t.index ["uid"], name: "index_performance_audits_on_uid"
  end

  create_table "puppeteer_recordings", charset: "utf8", force: :cascade do |t|
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

  create_table "release_check_batches", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.string "batch_uid"
    t.string "minute_interval"
    t.integer "num_tags_with_new_versions"
    t.integer "num_tags_without_new_versions"
    t.datetime "executed_at"
    t.datetime "processing_completed_at"
    t.float "ms_to_run_check"
    t.index ["batch_uid"], name: "index_release_check_batches_on_batch_uid"
    t.index ["uid"], name: "index_release_check_batches_on_uid"
  end

  create_table "release_checks", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.bigint "tag_id"
    t.boolean "content_is_the_same_as_a_previous_version"
    t.boolean "bytesize_changed"
    t.boolean "hash_changed"
    t.boolean "captured_new_tag_version"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "executed_at"
    t.bigint "release_check_batch_id"
    t.index ["release_check_batch_id"], name: "index_release_checks_on_release_check_batch_id"
    t.index ["tag_id"], name: "index_release_checks_on_tag_id"
    t.index ["uid"], name: "index_release_checks_on_uid"
  end

  create_table "roles", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.index ["uid"], name: "index_roles_on_uid"
  end

  create_table "tag_identifying_data", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.string "company"
    t.string "homepage"
    t.string "category"
    t.index ["uid"], name: "index_tag_identifying_data_on_uid"
  end

  create_table "tag_identifying_data_domains", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.bigint "tag_identifying_data_id"
    t.string "url_pattern"
    t.index ["tag_identifying_data_id"], name: "index_tag_identifying_data_domains_on_tag_identifying_data_id"
    t.index ["uid"], name: "index_tag_identifying_data_domains_on_uid"
    t.index ["url_pattern"], name: "index_tag_identifying_data_domains_on_url_pattern"
  end

  create_table "tag_url_patterns_to_not_capture", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.bigint "container_id"
    t.string "url_pattern"
    t.index ["container_id"], name: "index_tag_url_patterns_to_not_capture_on_container_id"
    t.index ["uid"], name: "index_tag_url_patterns_to_not_capture_on_uid"
  end

  create_table "tag_versions", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.integer "tag_id"
    t.integer "bytes"
    t.string "hashed_content"
    t.boolean "most_recent"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "total_changes"
    t.integer "num_additions"
    t.integer "num_deletions"
    t.text "commit_message"
    t.bigint "release_check_captured_with_id"
    t.string "sha_256"
    t.string "tag_version_identifier"
    t.string "sha_512"
    t.bigint "primary_audit_id"
    t.boolean "blocked_from_promoting_to_live"
    t.integer "original_content_byte_size"
    t.integer "tagsafe_minified_byte_size"
    t.index ["primary_audit_id"], name: "index_tag_versions_on_primary_audit_id"
    t.index ["release_check_captured_with_id"], name: "index_tag_versions_on_release_check_captured_with_id"
    t.index ["tag_id"], name: "index_tag_versions_on_tag_id"
    t.index ["uid"], name: "index_tag_versions_on_uid"
  end

  create_table "tags", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.integer "container_id"
    t.bigint "tag_identifying_data_id"
    t.string "url_hostname"
    t.string "url_path"
    t.text "url_query_param"
    t.text "full_url"
    t.integer "last_captured_byte_size"
    t.datetime "marked_as_pending_tag_version_capture_at"
    t.timestamp "last_released_at"
    t.timestamp "created_at"
    t.datetime "deleted_at"
    t.bigint "current_live_tag_version_id"
    t.boolean "has_staged_changes"
    t.bigint "most_recent_tag_version_id"
    t.boolean "is_tagsafe_hosted"
    t.datetime "last_seen_at"
    t.datetime "removed_from_site_at"
    t.bigint "tagsafe_js_event_batch_id"
    t.integer "release_monitoring_interval_in_minutes"
    t.string "load_type"
    t.boolean "is_tagsafe_js_interceptable"
    t.integer "tagsafe_js_intercepted_count"
    t.integer "tagsafe_js_optimized_count"
    t.integer "tagsafe_js_not_intercepted_count"
    t.boolean "is_tagsafe_hostable"
    t.bigint "primary_audit_id"
    t.bigint "page_load_found_on_id"
    t.string "configured_load_type"
    t.index ["container_id"], name: "index_tags_on_container_id"
    t.index ["current_live_tag_version_id"], name: "index_tags_on_current_live_tag_version_id"
    t.index ["most_recent_tag_version_id"], name: "index_tags_on_most_recent_tag_version_id"
    t.index ["page_load_found_on_id"], name: "index_tags_on_page_load_found_on_id"
    t.index ["primary_audit_id"], name: "index_tags_on_primary_audit_id"
    t.index ["tag_identifying_data_id"], name: "index_tags_on_tag_identifying_data_id"
    t.index ["tagsafe_js_event_batch_id"], name: "index_tags_on_tagsafe_js_event_batch_id"
    t.index ["uid"], name: "index_tags_on_uid"
  end

  create_table "tagsafe_js_event_batches", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.string "cloudflare_message_id"
    t.bigint "container_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.timestamp "tagsafe_js_ts"
    t.timestamp "enqueued_at"
    t.timestamp "tagsafe_consumer_received_at"
    t.timestamp "tagsafe_consumer_processed_at"
    t.float "seconds_to_complete"
    t.bigint "page_url_id"
    t.index ["cloudflare_message_id"], name: "index_tagsafe_js_event_batches_on_cloudflare_message_id"
    t.index ["container_id"], name: "index_tagsafe_js_event_batches_on_container_id"
    t.index ["page_url_id"], name: "index_tagsafe_js_event_batches_on_page_url_id"
    t.index ["uid"], name: "index_tagsafe_js_event_batches_on_uid"
  end

  create_table "test_runs", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.string "type"
    t.bigint "functional_test_id"
    t.bigint "audit_id"
    t.bigint "original_test_run_with_tag_id"
    t.integer "test_run_id_retried_from"
    t.string "results"
    t.boolean "passed"
    t.text "logs", size: :medium
    t.text "puppeteer_script_ran"
    t.string "expected_results"
    t.string "error_message"
    t.string "error_type"
    t.text "error_trace"
    t.integer "script_execution_ms"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "enqueued_at"
    t.datetime "completed_at"
    t.datetime "lambda_response_received_at"
    t.index ["audit_id"], name: "index_test_runs_on_audit_id"
    t.index ["functional_test_id"], name: "index_test_runs_on_functional_test_id"
    t.index ["original_test_run_with_tag_id"], name: "index_test_runs_on_original_test_run_with_tag_id"
    t.index ["test_run_id_retried_from"], name: "index_test_runs_on_test_run_id_retried_from"
    t.index ["uid"], name: "index_test_runs_on_uid"
  end

  create_table "triggered_alerts", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.bigint "tag_id"
    t.string "initiating_record_type"
    t.bigint "initiating_record_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "alert_configuration_id"
    t.index ["alert_configuration_id"], name: "index_triggered_alerts_on_alert_configuration_id"
    t.index ["initiating_record_type", "initiating_record_id"], name: "index_triggered_alerts_on_initiating_record"
    t.index ["tag_id"], name: "index_triggered_alerts_on_tag_id"
    t.index ["uid"], name: "index_triggered_alerts_on_uid"
  end

  create_table "uptime_check_batches", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.string "batch_uid"
    t.bigint "uptime_region_id"
    t.integer "num_tags_checked"
    t.datetime "executed_at"
    t.datetime "processing_completed_at"
    t.float "ms_to_run_check"
    t.index ["batch_uid"], name: "index_uptime_check_batches_on_batch_uid"
    t.index ["uid"], name: "index_uptime_check_batches_on_uid"
    t.index ["uptime_region_id"], name: "index_uptime_check_batches_on_uptime_region_id"
  end

  create_table "uptime_checks", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.float "response_time_ms"
    t.integer "response_code"
    t.timestamp "created_at"
    t.integer "tag_id"
    t.datetime "executed_at"
    t.bigint "uptime_region_id"
    t.bigint "uptime_check_batch_id"
    t.index ["tag_id"], name: "index_uptime_checks_on_tag_id"
    t.index ["uid"], name: "index_uptime_checks_on_uid"
    t.index ["uptime_check_batch_id"], name: "index_uptime_checks_on_uptime_check_batch_id"
    t.index ["uptime_region_id"], name: "index_uptime_checks_on_uptime_region_id"
  end

  create_table "uptime_regions", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.string "aws_name"
    t.string "location"
    t.index ["aws_name"], name: "index_uptime_regions_on_aws_name"
    t.index ["uid"], name: "index_uptime_regions_on_uid"
  end

  create_table "uptime_regions_to_check", charset: "utf8", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "uid"
    t.bigint "uptime_region_id"
    t.index ["tag_id"], name: "index_uptime_regions_to_check_on_tag_id"
    t.index ["uid"], name: "index_uptime_regions_to_check_on_uid"
    t.index ["uptime_region_id"], name: "index_uptime_regions_to_check_on_uptime_region_id"
  end

  create_table "urls_to_audit", charset: "utf8", force: :cascade do |t|
    t.bigint "tag_id"
    t.boolean "primary"
    t.string "uid"
    t.bigint "page_url_id"
    t.index ["page_url_id"], name: "index_urls_to_audit_on_page_url_id"
    t.index ["tag_id"], name: "index_urls_to_audit_on_tag_id"
    t.index ["uid"], name: "index_urls_to_audit_on_uid"
  end

  create_table "user_invites", charset: "utf8", force: :cascade do |t|
    t.string "uid"
    t.integer "container_id"
    t.string "email"
    t.string "token"
    t.timestamp "expires_at"
    t.timestamp "created_at"
    t.integer "invited_by_user_id"
    t.timestamp "redeemed_at"
    t.bigint "redeemed_by_user_id"
    t.index ["container_id"], name: "index_user_invites_on_container_id"
    t.index ["invited_by_user_id"], name: "index_user_invites_on_invited_by_user_id"
    t.index ["redeemed_by_user_id"], name: "index_user_invites_on_redeemed_by_user_id"
    t.index ["token"], name: "index_user_invites_on_token"
    t.index ["uid"], name: "index_user_invites_on_uid"
  end

  create_table "users", charset: "utf8", force: :cascade do |t|
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

end
