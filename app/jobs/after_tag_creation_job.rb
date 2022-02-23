class AfterTagCreationJob < ApplicationJob
  def perform(tag)
    ActiveRecord::Base.transaction do
      tag.run_tag_check! if tag.enabled?
      unless tag.found_on_url_crawl.is_first_crawl_for_domain_with_found_tags?
        NotificationModerator::NewTagNotifier.new(tag).notify!
      end
    end
  end
end