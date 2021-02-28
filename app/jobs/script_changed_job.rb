class ScriptChangedJob < ApplicationJob
  # queue_as :script_changed_notifier_job

  def perform(script_change)
    unless script_change.first_change?
      script_change.notify_script_change!
    end
    script_change.script.script_subscribers.should_run_audits.each do |script_subscriber|
      if script_subscriber.should_throttle_audit?(script_change)
        script_subscriber.throttle_audit!(script_change)
      else
        # script_change.lint!(script_subscriber)
        script_subscriber.run_audit!(script_change, script_change.first_change? ? ExecutionReason.INITIAL_AUDIT : ExecutionReason.TAG_CHANGE)
      end
    end
  end
end