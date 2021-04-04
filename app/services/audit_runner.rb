class AuditRunner
  include Rails.application.routes.url_helpers
  
  def initialize(tag_version:, execution_reason:, num_attempts: 0)
    @tag_version = tag_version
    @tag = @tag_version.tag
    @execution_reason = execution_reason
    @num_attempts = num_attempts
  end

  def run!
    performance_audit_runner.send!
  end

  private

  def performance_audit_runner
    @performance_audit_runner ||= GeppettoModerator::Senders::RunPerformanceAudit.new(
      audit: audit,
      audit_url: @tag.performance_audit_preferences.url_to_audit,
      num_test_iterations: @tag.performance_audit_preferences.num_test_iterations,
      third_party_tag_url_patterns_to_allow: allowed_third_party_tags,
      third_party_tags_to_overwrite: [{ request_url: @tag.full_url, overwrite_url: @tag_version.google_cloud_js_file_url }],
      num_attempts: @num_attempts
    )
  end

  def audit
    @audit ||= Audit.create(
      tag_version: @tag_version,
      tag: @tag,
      execution_reason: @execution_reason,
      performance_audit_url: @tag.performance_audit_preferences.url_to_audit,
      performance_audit_enqueued_at: DateTime.now
    )
  end

  def allowed_third_party_tags
    @tag.domain.allowed_third_party_tag_urls.concat(
      @tag.tag_allowed_performance_audit_third_party_urls.collect(&:url_pattern)
    ).concat(
      @tag.domain.non_third_party_url_patterns.collect(&:pattern)
    )
  end
end
