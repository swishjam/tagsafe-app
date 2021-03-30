class ScriptChangedJob < ApplicationJob
  # queue_as :script_changed_notifier_job

  def perform(script_change)
    NotificationModerator::ScriptChangeNotifier.new(script_change).notify!
    script_change.script.script_subscribers.should_run_audits.each do |script_subscriber|
      if script_subscriber.should_throttle_audit?(script_change)
        script_subscriber.throttle_audit!(script_change)
      else
        # script_change.lint!(script_subscriber)
        script_subscriber.run_audit!(script_change, script_change.first_change? ? ExecutionReason.INITIAL_AUDIT : ExecutionReason.TAG_CHANGE)
      end
    end
    DataRetention::ScriptChanges.new(script_change).purge!
  end
end