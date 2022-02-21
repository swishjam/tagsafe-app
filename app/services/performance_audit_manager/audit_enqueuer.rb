module PerformanceAuditManager
  class AuditEnqueuer
    def initialize(audit, performance_audit_type_just_completed = nil)
      # reload to see if it fixes bug where we never reach performance_audit_completed! due to race conditions in simulataneous performance audits
      @audit = audit.reload
      @performance_audit_type_just_completed = performance_audit_type_just_completed
    end

    def enqueue_initial_performance_audits!
      if Util.env_is_true('ENQUEUE_INDIVIDUAL_PERFORMANCE_AUDITS_SIMULTANEOUSLY')
        (ENV['NUM_SIMULTAENOUS_INDIVIDUAL_PERFORMANCE_AUDITS'] || 1).to_i.times do
          enqueue_individual_performance_audit!(IndividualPerformanceAuditWithTag.SYMBOLIZED_AUDIT_TYPE)
          enqueue_individual_performance_audit!(IndividualPerformanceAuditWithoutTag.SYMBOLIZED_AUDIT_TYPE)
        end
      else
        enqueue_individual_performance_audit!(IndividualPerformanceAuditWithTag.SYMBOLIZED_AUDIT_TYPE)
      end
    end
    
    def enqueue_next_performance_audit!(audit_type_to_enqueue = nil)
      if @audit.num_individual_performance_audits_remaining.zero?
        @audit.performance_audit_completed!
      elsif @audit.individual_performance_audits.failed.count >= @audit.maximum_individual_performance_audit_attempts
        audit_reached_maximum_failed_performance_audits!
      else
        if Util.env_is_true('ENQUEUE_INDIVIDUAL_PERFORMANCE_AUDITS_SIMULTANEOUSLY')
          enqueue_next_individual_performance_audit_simutaneously!
        else
          enqueue_next_individual_performance_audit_one_by_one!
        end
      end
    end

    private

    def enqueue_next_individual_performance_audit_simutaneously!
      enqueue_individual_performance_audit!(@performance_audit_type_just_completed)
    end

    def enqueue_next_individual_performance_audit_one_by_one!
      next_audit_type = @performance_audit_type_just_completed == IndividualPerformanceAuditWithTag.SYMBOLIZED_AUDIT_TYPE ? IndividualPerformanceAuditWithoutTag.SYMBOLIZED_AUDIT_TYPE : IndividualPerformanceAuditWithTag.SYMBOLIZED_AUDIT_TYPE
      if completed_all_individual_performance_audits_for_type?(next_audit_type)
        next_audit_type = @performance_audit_type_just_completed
      end
      enqueue_individual_performance_audit!(next_audit_type)
    end

    def completed_all_individual_performance_audits_for_type?(audit_type)
      @audit.send(:"num_individual_performance_audits_#{audit_type}_remaining").zero?
    end

    def enqueue_individual_performance_audit!(audit_type)
      Rails.logger.info "Enqueuing next #{audit_type} performance audit for Audit #{@audit.uid}, #{@audit.num_individual_performance_audits_remaining} remaining to complete."
      AuditRunnerJobs::RunIndividualPerformanceAudit.perform_later(type: audit_type, audit: @audit, tag_version: @audit.tag_version)
    end

    def audit_reached_maximum_failed_performance_audits!
      err_msg = "Reached maximum performance audit retry count of #{@audit.maximum_individual_performance_audit_attempts}, stopping audit."
      Rails.logger.error err_msg
      @audit.performance_audit_error!(err_msg)
    end
  end
end