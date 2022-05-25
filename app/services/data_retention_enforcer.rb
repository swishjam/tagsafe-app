class DataRetentionEnforcer
  def initialize(domain)
    @domain = domain
    @days_of_retention_for_domain = @domain.subscription_features_configuration.data_retention_days
    @release_check_and_uptime_check_retention_days = @days_of_retention_for_domain > 7 ? 14 : @days_of_retention_for_domain
  end

  def purge_out_of_retention_data!
    start = Time.current
    Rails.logger.info "DataRetentionEnforcer: Beginning to purge data for Domain #{@domain.uid} (#{@domain.url})"
    
    purge_tag_versions!
    purge_audits!
    purge_uptime_checks!
    purge_release_checks!
    purge_url_crawls!

    Rails.logger.info "DataRetentionEnforcer: Completed purge for Domain #{@domain.uid} (#{@domain.url}) in #{Time.current - domain_start} seconds."
  end

  private

  def purge_tag_versions!
    if @domain.tag_versions.count == 1
      Rails.logger.info "DataRetentionEnforcer: Not purging the only TagVersion left for Domain #{@domain.uid} event though it is older than it's retention period."
    else
      tag_versions_to_purge = @domain.tag_versions.older_than(Time.current - @days_of_retention_for_domain.days)
      Rails.logger.info "DataRetentionEnforcer: Purging #{tag_versions_to_purge.count} TagVersions that are older than #{@days_of_retention_for_domain} days."
      tag_versions_to_purge.destroy_all_fully!
    end
  end

  def purge_audits!
    audits_to_purge = @domain.audits.older_than(Time.current - @days_of_retention_for_domain.days)
    Rails.logger.info "DataRetentionEnforcer: Purging #{audits_to_purge.count} Audits that are older than #{@days_of_retention_for_domain} days."
    audits_to_purge.destroy_all
  end

  def purge_uptime_checks!
    uptime_checks_to_purge = @domain.uptime_checks.older_than(Time.current - @release_check_and_uptime_check_retention_days.days, timestamp_column: :'uptime_checks.executed_at')
    Rails.logger.info "DataRetentionEnforcer: Purging #{uptime_checks_to_purge.count} UptimeChecks that are older than #{@release_check_and_uptime_check_retention_days} days."
    uptime_checks_to_purge.delete_all
  end

  def purge_release_checks!
    release_checks_to_purge = @domain.release_checks.older_than(Time.current - @release_check_and_uptime_check_retention_days.days, timestamp_column :'release_checks.executed_at')
    Rails.logger.info "DataRetentionEnforcer: Purging #{release_checks_to_purge.count} ReleaseChecks that are older than #{@release_check_and_uptime_check_retention_days} days."
    release_checks_to_purge.delete_all
  end

  def purge_url_crawls!
    url_crawls_to_purge = @domain.url_crawls.includes(:retrieved_urls).older_than(Time.current - @days_of_retention_for_domain.days)
    Rails.logger.info "DataRetentionEnforcer: Purging #{url_crawls_to_purge.count} UrlCrawls that are older than #{@days_of_retention_for_domain} days."
    url_crawls_to_purge.retrieved_urls.delete_all
    url_crawls_to_purge.delete_all
  end
end