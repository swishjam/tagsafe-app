class DefaultAuditConfiguration < ApplicationRecord
  self.table_name = :default_audit_configuration
  belongs_to :parent, polymorphic: true

  def self.create_default_for_domain(domain)
    create!(
      parent: domain,
      include_performance_audit: true,
      include_page_load_resources: true,
      include_page_change_audit: true,
      include_functional_tests: true,
      num_perf_audit_iterations: 3,
      perf_audit_strip_all_images: true,
      perf_audit_include_page_tracing: false,
      perf_audit_throw_error_if_dom_complete_is_zero: true,
      perf_audit_inline_injected_script_tags: false,
      perf_audit_scroll_page: false,
      perf_audit_enable_screen_recording: true,
      perf_audit_override_initial_html_request_with_manipulated_page: true
    )
  end
end