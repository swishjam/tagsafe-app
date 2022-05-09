module Schedule
  module CrawlUrlsJobs
    class TwentyFourHourInterval < ApplicationJob
      def perform
        domains = Domain.where_subscription_feature_restriction(tag_sync_minute_cadence: 1_440)
        Rails.logger.info "Schedule::CrawlUrlsJobs::TwentyFourHourInterval - Crawling #{domains.count} domains that have a SubscriptionFeatureRestriction `tag_sync_minute_cadence` = 1_440 for new/removed tags."
        domains.each do |domain|
          domain.page_urls.should_scan_for_tags.each(&:crawl_for_tags!)
        end
      end
    end
  end
end