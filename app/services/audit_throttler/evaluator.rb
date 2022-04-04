module AuditThrottler
  class Evaluator
    def initialize(tag_version)
      @tag_version = tag_version
      @tag = tag_version.tag
    end

    def should_throttle?
      return false if @tag.tag_preferences.throttle_minute_threshold.nil?
      @tag.tag_preferences.throttle_minute_threshold < minutes_between_last_tag_change_audit
    end

    def throttle!
      @tag.audits.create(
        throttled: true,
        tag_version: @tag_version,
        execution_reason: ExecutionReason.NEW_RELEASE,
        primary: true,
        enqueued_suite_at: DateTime.now
        # seconds_to_complete: 0
      )
    end

    private

    def minutes_between_last_tag_change_audit
      return 0 if most_recent_tag_change_audit.nil?
      seconds_since = @tag_version.created_at - most_recent_tag_change_audit.tag_version.created_at
      seconds_since / 60.0
    end

    def most_recent_tag_change_audit
      @last_tag_change_audit ||= @tag.audits.not_throttled.where(execution_reason: ExecutionReason.NEW_RELEASE).most_recent_first.limit(1).first
    end
  end
end