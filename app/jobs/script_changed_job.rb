class ScriptChangedJob < ApplicationJob
  # queue_as :script_changed_notifier_job

  def perform(script_change)
    unless script_change.first_change?
      script_change.script.script_change_notification_subscribers.active.still_on_site.each do |change_subscriber|
        change_subscriber.send_email!(script_change)
      end
    end
    execution_reason = script_change.first_change? ? ExecutionReason.FIRST_AUDIT : ExecutionReason.SCRIPT_CHANGE
    script_change.script.script_subscribers.active.still_on_site.each do |script_subscriber|
      script_subscriber.run_audit!(script_change, execution_reason)
    end
  end
end