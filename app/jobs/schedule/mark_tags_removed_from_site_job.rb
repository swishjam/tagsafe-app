module Schedule
  class MarkTagsRemovedFromSiteJob
    def perform
      Tag.where('last_seen_in_url_crawl_at < ?', 2.days.ago).update_all(removed_from_site_at: Time.now)
    end
  end
end