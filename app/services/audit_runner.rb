class AuditRunner
  include Rails.application.routes.url_helpers
  
  def initialize(script_subscriber:, script_change:, execution_reason:, existing_audit: nil, num_attempts: 0)
    @script_subscriber = script_subscriber.reload
    @script_change = script_change
    @execution_reason = execution_reason
    @existing_audit = existing_audit
    @num_attempts = num_attempts
  end

  def run!
    performance_audit_runner.send!
  end

  private

  def performance_audit_runner
    @performance_audit_runner ||= GeppettoModerator::Senders::RunPerformanceAudit.new(
      audit: audit,
      audit_url: @script_subscriber.performance_audit_preferences.url_to_audit,
      num_test_iterations: @script_subscriber.performance_audit_preferences.num_test_iterations,
      # third_party_tag_to_audit: @script_subscriber.script.url,
      third_party_tag_url_patterns_to_allow: allowed_third_party_tags,
      third_party_tags_to_overwrite: [{ request_url: @script_subscriber.script.url, overwrite_url: @script_change.google_cloud_js_file_url }],
      num_attempts: @num_attempts
    )
  end

  def test_suite_runner
    raise 'Need to figure out tests....'
  end

  def audit
    @audit ||= existing_audit || Audit.create(
      script_change: @script_change,
      script_subscriber: @script_subscriber,
      execution_reason: @execution_reason,
      performance_audit_url: @script_subscriber.performance_audit_preferences.url_to_audit,
      performance_audit_enqueued_at: DateTime.now,
      test_suite_enqueued_at: DateTime.now,
      test_suite_completed_at: DateTime.now
    )
  end

  def existing_audit
    return nil if @existing_audit.nil?
    @existing_audit.update(
      performance_audit_enqueued_at: DateTime.now,
      test_suite_enqueued_at: DateTime.now,
      test_suite_completed_at: DateTime.now
    )
    @existing_audit
  end

  def allowed_third_party_tags
    @script_subscriber.domain.allowed_third_party_tag_urls.concat(@script_subscriber.allowed_performance_audit_tags.collect(&:url_pattern))
  end
end
