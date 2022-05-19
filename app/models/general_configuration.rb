class GeneralConfiguration < ApplicationRecord
  belongs_to :parent, polymorphic: true

  before_destroy :cant_destroy_domain_parent

  def self.create_default_for_domain(domain)
    create!(
      parent: domain,
      include_performance_audit: true,
      include_page_load_resources: Util.env_is_true('INCLUDE_PAGE_LOAD_RESOURCES_IN_DEFAULT_AUDIT_CONFIGURATION'),
      include_page_change_audit: Util.env_is_true('INCLUDE_PAGE_LOAD_RESOURCES_IN_DEFAULT_AUDIT_CONFIGURATION'),
      include_functional_tests: true,
      enable_monitoring_on_new_tags: true,
      roll_up_audits_by_tag_version: false,
      num_recent_tag_versions_to_compare_in_release_monitoring: 5,
      # num_perf_audits_to_run: 3,
      perf_audit_batch_size: 3,
      perf_audit_minimum_num_sets: 3,
      perf_audit_maximum_num_sets: 20,
      perf_audit_max_failures: 6,
      perf_audit_fail_when_confidence_range_not_met: false,
      perf_audit_completion_indicator_type: PerformanceAudit.CONFIDENCE_RANGE_COMPLETION_INDICATOR_TYPE,
      perf_audit_required_tagsafe_score_range: (ENV['PERFORMANCE_AUDIT_DEFAULT_REQUIRED_TAGSAFE_SCORE_RANGE'] || 5.0).to_f,
      perf_audit_strip_all_images: false,
      perf_audit_include_page_tracing: true,
      perf_audit_throw_error_if_dom_complete_is_zero: true,
      perf_audit_inline_injected_script_tags: false,
      perf_audit_scroll_page: false,
      perf_audit_enable_screen_recording: true,
      perf_audit_override_initial_html_request_with_manipulated_page: true
    )
  end

  private

  def cant_destroy_domain_parent
    if parent.is_a?(Domain)
      errors.add(:base, "Cannot destroy the Default Audit GeneralConfiguration for domain.")
    end
  end
end