class DataRetentionEnforcer
  def initialize(container)
    @container = container
    @days_of_retention_for_container = 30
    @release_check_and_uptime_check_retention_days = @days_of_retention_for_container > 7 ? 14 : @days_of_retention_for_container
  end

  def purge_out_of_retention_data!
    start = Time.current
    Rails.logger.info "DataRetentionEnforcer: Beginning to purge data for Container #{@container.uid} (#{@container.name})"
    
    purge_tag_versions!
    purge_audits!
    purge_uptime_checks!
    purge_release_checks!

    Rails.logger.info "DataRetentionEnforcer: Completed purge for Container #{@container.uid} (#{@container.name}) in #{Time.current - start} seconds."
  end

  private

  def purge_tag_versions!
    if @container.tag_versions.count == 1
      Rails.logger.info "DataRetentionEnforcer: Not purging the only TagVersion left for Container #{@container.uid} event though it is older than it's retention period."
    else
      tag_versions_to_purge = @container.tag_versions.older_than(Time.current - @days_of_retention_for_container.days, timestamp_column: :'tag_versions.created_at')
      Rails.logger.info "DataRetentionEnforcer: Purging #{tag_versions_to_purge.count} TagVersions that are older than #{@days_of_retention_for_container} days."
      tag_versions_to_purge.destroy_all_fully!
    end
  end

  def purge_audits!
    audits_to_purge = @container.audits.older_than(Time.current - @days_of_retention_for_container.days, timestamp_column: :'audits.created_at')
    Rails.logger.info "DataRetentionEnforcer: Purging #{audits_to_purge.count} Audits that are older than #{@days_of_retention_for_container} days."
    audits_to_purge.destroy_all
  end

  def purge_uptime_checks!
    uptime_checks_to_purge = @container.uptime_checks.older_than(Time.current - @release_check_and_uptime_check_retention_days.days, timestamp_column: :'uptime_checks.executed_at')
    Rails.logger.info "DataRetentionEnforcer: Purging #{uptime_checks_to_purge.count} UptimeChecks that are older than #{@release_check_and_uptime_check_retention_days} days."
    uptime_checks_to_purge.delete_all
  end

  def purge_release_checks!
    release_checks_to_purge = @container.release_checks.older_than(Time.current - @release_check_and_uptime_check_retention_days.days, timestamp_column: :'release_checks.executed_at')
    Rails.logger.info "DataRetentionEnforcer: Purging #{release_checks_to_purge.count} ReleaseChecks that are older than #{@release_check_and_uptime_check_retention_days} days."
    release_checks_to_purge.delete_all
  end
end