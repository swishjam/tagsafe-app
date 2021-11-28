class AfterTagCreationJob < ApplicationJob
  def perform(tag, initial_crawl)
    NotificationModerator::NewTagNotifier.new(tag).notify! unless initial_crawl
  end
end