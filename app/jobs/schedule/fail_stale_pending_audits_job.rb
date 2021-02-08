module Schedule
  class FailStalePendingAuditsJob < ApplicationJob
    def perform
      Audit.pending_performance_audit.older_than(Time.now - fail_period).each do |audit|
        Resque.logger.info "Purging audit ID #{audit.id} that exceeds fail period."
        audit.performance_audit_error!("Audit timeout after #{fail_period} seconds.", Float::INFINITY) # never retry these
      end
    end

    def fail_period
      (ENV['FAIL_STALE_PENDING_MINUTES_AGO'] ? ENV['FAIL_STALE_PENDING_MINUTES_AGO'].to_i : 60).minutes
    end
  end
end