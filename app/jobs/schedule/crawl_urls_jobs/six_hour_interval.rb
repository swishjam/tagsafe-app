module Schedule
  module CrawlUrlsJobs
    class SixHourInterval < ApplicationJob
      def perform
        domains = Domain.where_subscription_features_configuration(tag_sync_minute_cadence: 360)
        Rails.logger.info "Schedule::CrawlUrlsJobs::SixHourInterval - Crawling #{domains.count} domains that have a SubscriptionFeaturesConfiguration `tag_sync_minute_cadence` = 360 for new/removed tags."
        domains.each do |domain|
          domain.page_urls.should_scan_for_tags.each(&:crawl_for_tags!)
        end
      end
    end
  end
end