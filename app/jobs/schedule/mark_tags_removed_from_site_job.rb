module Schedule
  class MarkTagsRemovedFromSiteJob
    def perform
      tags_to_remove = Tag.where('last_seen_in_url_crawl_at < ?', 2.days.ago)
      tags_to_remove.each(&:mark_as_removed_from_site!)
      Rails.logger.info "Schedule::MarkTagsRemovedFromSiteJob removed #{tags_to_remove.count} tags."
    end
  end
end