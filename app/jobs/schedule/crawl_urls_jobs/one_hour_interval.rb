module Schedule
  module CrawlUrlsJobs
    class OneHourInterval < ApplicationJob
      def perform
        domains = Domain.has_valid_subscription.where_subscription_features_configuration(tag_sync_minute_cadence: 60)
        Rails.logger.info "Schedule::CrawlUrlsJobs::OneHourInterval - Crawling #{domains.count} domains that have a SubscriptionFeaturesConfiguration `tag_sync_minute_cadence` = 60 for new/removed tags."
        domains.each do |domain|
          domain.page_urls.should_scan_for_tags.each(&:crawl_for_tags!)
        end
      end
    end
  end
end