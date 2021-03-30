class AfterScriptSubscriberCreationJob < ApplicationJob
  def perform(script_subscriber)
    NotificationModerator::NewTagNotifier.new(script_subscriber).notify!
  end
end