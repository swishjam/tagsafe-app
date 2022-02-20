module PerformanceAuditManager
  class AuditEnqueuer
    def initialize(audit, performance_audit_type_just_completed = nil)
      # reload to see if it fixes bug where we never reach performance_audit_completed! due to race conditions in simulataneous performance audits
      @audit = audit.reload
      @performance_audit_type_just_completed = performance_audit_type_just_completed
    end
    
    def enqueue_next_performance_audit!(audit_type_to_enqueue = nil)
      if Util.env_is_true('ENQUEUE_INDIVIDUAL_PERFORMANCE_AUDITS_SIMULTANEOUSLY')
        enqueue_next_individual_performance_audit_simutaneously_if_necessary!
      else
        enqueue_next_individual_performance_audit_one_by_one_if_necessary!
      end
    end

    private

    def enqueue_next_individual_performance_audit_simutaneously_if_necessary!
      if completed_all_individual_performance_audits?
        Rails.logger.info "All performance audits are completed!"
        @audit.performance_audit_completed!
      elsif completed_all_individual_performance_audits_for_type?(@performance_audit_type_just_completed)
        Rails.logger.info "Audit #{@audit.uid} completed performance audits for #{@performance_audit_type_just_completed} but still has #{@audit.num_individual_performance_audits_remaining} to complete, letting other audit_type handle it."
      elsif audit_exceeded_maximum_failed_performance_audits?
        audit_reached_maximum_failed_performance_audits!
      else
        enqueue_individual_performance_audit!(@performance_audit_type_just_completed)
      end
    end

    def enqueue_next_individual_performance_audit_one_by_one_if_necessary!
      if completed_all_individual_performance_audits?
        Rails.logger.info "All performance audits are completed!"
        @audit.performance_audit_completed!
      elsif audit_exceeded_maximum_failed_performance_audits?
        audit_reached_maximum_failed_performance_audits!
      else
        next_audit_type = @performance_audit_type_just_completed == IndividualPerformanceAuditWithTag.SYMBOLIZED_AUDIT_TYPE ? IndividualPerformanceAuditWithoutTag.SYMBOLIZED_AUDIT_TYPE : IndividualPerformanceAuditWithTag.SYMBOLIZED_AUDIT_TYPE
        if completed_all_individual_performance_audits_for_type?(next_audit_type)
          next_audit_type = @performance_audit_type_just_completed
        end
        enqueue_individual_performance_audit!(next_audit_type)
      end
    end

    def completed_all_individual_performance_audits_for_type?(audit_type)
      @audit.send(:"num_individual_performance_audits_#{audit_type}_remaining").zero?
    end

    def completed_all_individual_performance_audits?
      @audit.num_individual_performance_audits_remaining.zero?
    end

    def enqueue_individual_performance_audit!(audit_type)
      Rails.logger.info "Enqueuing next #{audit_type} performance audit for Audit #{@audit.uid}, #{@audit.num_individual_performance_audits_remaining} remaining to complete."
      AuditRunnerJobs::RunIndividualPerformanceAudit.perform_later(type: audit_type, audit: @audit, tag_version: @audit.tag_version)
    end

    def audit_exceeded_maximum_failed_performance_audits?
      @audit.individual_performance_audits.failed.count >= @audit.maximum_individual_performance_audit_attempts
    end

    def audit_reached_maximum_failed_performance_audits!
      err_msg = "Reached maximum performance audit retry count of #{@audit.maximum_individual_performance_audit_attempts}, stopping audit."
      Rails.logger.error err_msg
      @audit.performance_audit_error!(err_msg)
    end
  end
end