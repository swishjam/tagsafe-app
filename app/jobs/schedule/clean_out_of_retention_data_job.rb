module Schedule
  class CleanOutOfRetentionDataJob < ApplicationJob
    TAG_VERSION_RETENTION_OFFSET_BY_TAG = 100
    TAG_CHECK_RETENTION_OFFSET_BY_TAG = 1440*7 # 1 weeks worth at one minute checks
    NON_PRIMARY_AUDIT_OFFSET_FOR_TAG = 100
    NON_MEDIAN_DELTA_PERFORMANCE_AUDITS_OFFSET_BY_TAG = 100
    EXECUTED_LAMBDA_FUNCTION_OFFSET_FOR_TAG=100

    def perform
      purge_start = Time.now
      Domain.all.each do |domain|
        Rails.logger.info "DATA PURGE JOB: Beginning to purge data for Domain #{domain.url} (id: #{domain.id})"
        domain_start = Time.now
        domain.tags.each do |tag|
          purge_tag_checks_for_tag(tag)
          purge_tag_versions_for_tag(tag)
          purge_non_median_delta_performance_audits_for_tag(tag)
          purge_non_primary_audits_for_tag(tag)
        end
        Rails.logger.info "DATA PURGE JOB: completed purge for Domain #{domain.url} (#{domain.id}) in #{Time.now - domain_start} seconds"
      end
      Rails.logger.info "DATA PURGE JOB: completed entire purge in #{Time.now - purge_start}"
    end

    def purge_tag_checks_for_tag(tag)
      tag_checks = tag.tag_checks.most_recent_first.offset(TAG_CHECK_RETENTION_OFFSET_BY_TAG)
      Rails.logger.info "DATA PURGE JOB: purging #{tag_checks.count} of tag #{tag.try_friendly_name} (ID: #{tag.id}) tag checks (keeping #{TAG_CHECK_RETENTION_OFFSET_BY_TAG} of them)."
      tag_checks.destroy_all
    end

    def purge_tag_versions_for_tag(tag)
      tag_versions = tag.tag_versions.most_recent_first.offset(TAG_VERSION_RETENTION_OFFSET_BY_TAG)
      Rails.logger.info "DATA PURGE JOB: purging #{tag_versions.count} of tag #{tag.try_friendly_name} (ID: #{tag.id}) tag versions (keeping #{TAG_VERSION_RETENTION_OFFSET_BY_TAG} of them)."
      tag_versions.destroy_all_fully!
    end

    def purge_non_median_delta_performance_audits_for_tag(tag)
      delta_performance_audits = DeltaPerformanceAudit.joins(:audit)
                                                              .where(type: IndividualDeltaPerformanceAudit.to_s, audit: tag.audits)
                                                              .offset(NON_MEDIAN_DELTA_PERFORMANCE_AUDITS_OFFSET_BY_TAG)
      Rails.logger.info "DATA PURGE JOB: purging #{delta_performance_audits.count} of tag #{tag.try_friendly_name} (ID: #{tag.id}) non-median/average delta performance audits (keeping #{NON_MEDIAN_DELTA_PERFORMANCE_AUDITS_OFFSET_BY_TAG} of them)."
      delta_performance_audits.destroy_all
    end

    def purge_non_primary_audits_for_tag(tag)
      audits = tag.audits.most_recent_first.where(primary: false).offset(NON_PRIMARY_AUDIT_OFFSET_FOR_TAG)
      Rails.logger.info  "DATA PURGE JOB: purging #{audits.count} of tag #{tag.try_friendly_name} (ID: #{tag.id}) non primary audits (keeping #{NON_PRIMARY_AUDIT_OFFSET_FOR_TAG} of them)."
      audits.destroy_all
    end
  end
end