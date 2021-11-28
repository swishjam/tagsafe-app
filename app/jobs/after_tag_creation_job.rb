class AfterTagCreationJob < ApplicationJob
  def perform(tag, initial_crawl)
    tag.run_tag_check! if tag.enabled?
    NotificationModerator::NewTagNotifier.new(tag).notify! unless initial_crawl
  end
end