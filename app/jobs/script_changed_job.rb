class ScriptChangedJob < ApplicationJob
  # queue_as :script_changed_notifier_job

  def perform(script_change)
    unless script_change.first_change?
      script_change.script.script_change_notification_subscribers.should_receive_notifications.each do |change_subscriber|
        change_subscriber.send_email!(script_change)
      end
      script_change.script.script_changed_slack_notifications.should_receive_notifications.each do |slack_notification|
        slack_notification.notify!(script_change)
      end
    end
    script_change.script.script_subscribers.should_run_audits.each do |script_subscriber|
      script_change.lint!(script_subscriber)
      script_subscriber.run_audit!(script_change, script_change.first_change? ? ExecutionReason.INITIAL_AUDIT : ExecutionReason.TAG_CHANGE)
    end
  end
end