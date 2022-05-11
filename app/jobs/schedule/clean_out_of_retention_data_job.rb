module Schedule
  class CleanOutOfRetentionDataJob < ApplicationJob
    def perform
      purge_start = Time.current
      domains = Domain.all
      domains.each do |domain|
        Rails.logger.info "CleanOutOfRetentionDataJob: Beginning to purge data for Domain #{domain.uid} (#{domain.url})"
        domain_start = Time.current

        days_of_retention_for_domain = domain.subscription_feature_restriction.data_retention_days
        older_than_timestamp = Time.current - days_of_retention_for_domain.days
        
        if domain.tag_versions.count == 1
          Rails.logger.info "CleanOutOfRetentionDataJob: Not purging the only TagVersion left for Domain #{domain.uid} event though it is older than it's retention period."
        else
          tag_versions_to_purge = domain.tag_versions.older_than(older_than_timestamp)
          Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{tag_versions_to_purge.count} TagVersions that are older than #{days_of_retention_for_domain} days."
          tag_versions_to_purge.destroy_all_fully!
        end

        uptime_checks_to_purge = domain.uptime_checks.older_than(older_than_timestamp)
        Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{uptime_checks_to_purge.count} UptimeChecks that are older than #{days_of_retention_for_domain} days."
        uptime_checks_to_purge.destroy_all

        release_checks_to_purge = domain.release_checks.older_than(older_than_timestamp)
        Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{release_checks_to_purge.count} ReleaseChecks that are older than #{days_of_retention_for_domain} days."
        release_checks_to_purge.destroy_all

        audits_to_purge = domain.audits.older_than(older_than_timestamp)
        Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{audits_to_purge.count} Audits that are older than #{days_of_retention_for_domain} days."
        audits_to_purge.destroy_all

        url_crawls_to_purge = domain.url_crawls.older_than(older_than_timestamp)
        Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{url_crawls_to_purge.count} UrlCrawls that are older than #{days_of_retention_for_domain} days."
        url_crawls_to_purge.destroy_all

        Rails.logger.info "CleanOutOfRetentionDataJob: Completed purge for Domain #{domain.uid} (#{domain.url}) in #{Time.current - domain_start} seconds."
      end
      release_check_batches = ReleaseCheckBatch.older_than(14.days.ago, timestamp_column: :executed_at)
      Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{release_check_batches.count} ReleaseCheckBatches that are beyond the default retention period (14 days)"
      release_check_batches.destroy_all

      uptime_check_batches = ReleaseCheckBatch.older_than(14.days.ago, timestamp_column: :executed_at)
      Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{uptime_check_batches.count} UptimeCheckBatches that are beyond the default retention period (14 days)"


      Rails.logger.info "CleanOutOfRetentionDataJob: Completed entire purge of #{domains.count} Domains in #{Time.current - purge_start} seconds."
    end
  end
end