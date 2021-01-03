class AfterScriptSubscriberCreationJob < ApplicationJob
  def perform(script_subscriber, initial_scan = false)
    NotificationModerator::NewTagNotifier.new(script_subscriber).notify! unless initial_scan
  end
end