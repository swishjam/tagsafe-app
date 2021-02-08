module AuditThrottler
  class Evaluator
    def initialize(script_subscriber)
      @script_subscriber = script_subscriber
    end

    def should_throttle?(script_change)
      return false if @script_subscriber.throttle_minute_threshold.nil?
      @script_subscriber.throttle_minute_threshold < minutes_between_last_tag_change_audit(script_change)
    end

    def throttle!(script_change)
      @script_subscriber.audits.create(
        throttled: true,
        script_change: script_change,
        execution_reason: ExecutionReason.TAG_CHANGE,
        primary: true,
        performance_audit_enqueued_at: Time.now,
        performance_audit_completed_at: Time.now,
        test_suite_enqueued_at: Time.now,
        test_suite_completed_at: Time.now
      )
    end

    private

    def minutes_between_last_tag_change_audit(script_change)
      return 0 if last_tag_change_audit.nil?
      (script_change.created_at - last_tag_change_audit.script_change.created_at) / 60
    end

    def last_tag_change_audit
      @script_subscriber.audits.not_throttled.where(execution_reason: ExecutionReason.TAG_CHANGE).most_recent_first.limit(1).first
    end
  end
end