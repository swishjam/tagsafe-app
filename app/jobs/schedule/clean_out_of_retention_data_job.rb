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
        
        tag_versions_to_purge = domain.tag_versions.older_than(older_than_timestamp)
        Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{tag_versions_to_purge.count} TagVersions that are older than #{days_of_retention_for_domain} days."
        tag_versions_to_purge.destroy_all_fully!

        tag_checks_to_purge = domain.tag_checks.older_than(older_than_timestamp)
        Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{tag_checks_to_purge.count} TagChecks that are older than #{days_of_retention_for_domain} days."
        tag_checks_to_purge.destroy_all

        audits_to_purge = domain.audits.older_than(older_than_timestamp)
        Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{audits_to_purge.count} Audits that are older than #{days_of_retention_for_domain} days."
        audits_to_purge.destroy_all

        url_crawls_to_purge = domain.url_crawls.older_than(older_than_timestamp)
        Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{url_crawls_to_purge.count} UrlCrawls that are older than #{days_of_retention_for_domain} days."
        url_crawls_to_purge.destroy_all

        Rails.logger.info "CleanOutOfRetentionDataJob: Completed purge for Domain #{domain.uid} (#{domain.url}) in #{Time.current - domain_start} seconds."
      end
      Rails.logger.info "CleanOutOfRetentionDataJob: Completed entire purge of #{domains.count} Domains in #{Time.current - purge_start} seconds."
    end
  end
end