class CreateDefaultAuditConfiguration < ActiveRecord::Migration[6.1]
  def change
    create_table :default_audit_configuration do |t|
      t.string :uid, index: true
      t.references :parent, polymorphic: true
      t.boolean :include_performance_audit
      t.boolean :include_page_load_resources
      t.boolean :include_page_change_audit
      t.boolean :include_functional_tests
      t.integer :num_functional_tests_to_run
      t.integer :num_perf_audit_iterations
      t.boolean :perf_audit_strip_all_images
      t.boolean :perf_audit_include_page_tracing
      t.boolean :perf_audit_throw_error_if_dom_complete_is_zero
      t.boolean :perf_audit_inline_injected_script_tags
      t.boolean :perf_audit_scroll_page
      t.boolean :perf_audit_enable_screen_recording
      t.boolean :perf_audit_override_initial_html_request_with_manipulated_page
    end
  end
end
