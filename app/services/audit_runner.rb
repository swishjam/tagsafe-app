class AuditRunner
  def initialize(script_subscriber:, script_change:, execution_reason:)
    @script_subscriber = script_subscriber.reload
    @script_change = script_change
    @execution_reason = execution_reason
  end

  def run!
    lighthouse_audit_runner.send!
  end

  private

  def lighthouse_audit_runner
    @lighthouse_audit_runner ||= GeppettoModerator::Senders::RunLighthouseAudit.new(
      audit: audit, 
      url_to_audit: @script_subscriber.lighthouse_preferences.url_to_audit,
      num_test_iterations: @script_subscriber.lighthouse_preferences.num_test_iterations,
      script_url: @script_subscriber.script.url
    )
  end

  def test_suite_runner
    raise 'Need to figure out tests....'
  end

  def audit
    @audit ||= Audit.create(
      script_change: @script_change,
      script_subscriber: @script_subscriber,
      execution_reason: @execution_reason,
      lighthouse_audit_url: @script_subscriber.lighthouse_preferences.url_to_audit,
      lighthouse_audit_enqueued_at: DateTime.now,
      test_suite_enqueued_at: DateTime.now,
      test_suite_completed_at: DateTime.now
    )
  end
end
