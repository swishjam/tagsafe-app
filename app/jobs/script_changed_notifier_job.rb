class ScriptChangedNotifierJob < ApplicationJob
  queue_as :script_changed_notifier_job

  def perform(script_change)
    NotificationManager::Notifier.new(script_change).notify_all!
  end
end