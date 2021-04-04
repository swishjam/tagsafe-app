class AfterTagCreationJob < ApplicationJob
  def perform(tag)
    NotificationModerator::NewTagNotifier.new(tag).notify!
  end
end