module Schedule
  class CleanOutOfRetentionDataJob < ApplicationJob
    def perform
      purge_start = Time.current
      containers = Container.all
      containers.each{ |container| DataRetentionEnforcer.new(container).purge_out_of_retention_data! }
      release_check_batches = ReleaseCheckBatch.older_than(14.days.ago, timestamp_column: :executed_at)
      Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{release_check_batches.count} ReleaseCheckBatches that are beyond the default retention period (14 days)"
      release_check_batches.delete_all

      uptime_check_batches = ReleaseCheckBatch.older_than(14.days.ago, timestamp_column: :executed_at)
      Rails.logger.info "CleanOutOfRetentionDataJob: Purging #{uptime_check_batches.count} UptimeCheckBatches that are beyond the default retention period (14 days)"
      uptime_check_batches.delete_all

      Rails.logger.info "CleanOutOfRetentionDataJob: Completed entire purge of #{containers.count} Containers in #{Time.current - purge_start} seconds."
    end
  end
end