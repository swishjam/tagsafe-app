class AfterTagCreationJob < ApplicationJob
  def perform(tag, initial_crawl)
    ActiveRecord::Base.transaction do
      tag.run_tag_check! if tag.enabled?
      NotificationModerator::NewTagNotifier.new(tag).notify! unless initial_crawl
    end
  end
end