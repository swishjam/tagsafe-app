module PerformanceAuditManager
  class AuditEnqueuer
    def initialize(audit, performance_audit_just_completed_included_tag = nil)
      # reload to see if it fixes bug where we never reach performance_audit_completed! due to race conditions in simulataneous performance audits
      @audit = audit.reload
      @performance_audit_just_completed_included_tag = performance_audit_just_completed_included_tag
    end

    def enqueue_initial_performance_audits!
      if Util.env_is_true('ENQUEUE_INDIVIDUAL_PERFORMANCE_AUDITS_SIMULTANEOUSLY')
        (ENV['NUM_SIMULTAENOUS_INDIVIDUAL_PERFORMANCE_AUDITS'] || 1).to_i.times do
          enqueue_individual_performance_audit_with_tag!
          enqueue_individual_performance_audit_without_tag!
        end
      else
        enqueue_individual_performance_audit_with_tag!
      end
    end
    
    def enqueue_next_performance_audit!
      if @audit.num_individual_performance_audits_remaining <= 0
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
      @performance_audit_just_completed_included_tag ? enqueue_individual_performance_audit_with_tag! :  enqueue_individual_performance_audit_without_tag!
    end

    def enqueue_next_individual_performance_audit_one_by_one!
      # TODO: simplify this, maybe we just have with-tag audits enqueue with-tag audits,
      # without-tag audits enqueue without-tag audits instead of trying to alternate?
      include_tag_in_next_audit = completed_all_individual_performance_audits_for_type?(!@performance_audit_just_completed_included_tag) ? @performance_audit_just_completed_included_tag : !@performance_audit_just_completed_included_tag
      include_tag_in_next_audit ? enqueue_individual_performance_audit_with_tag! : enqueue_individual_performance_audit_without_tag!
    end

    def completed_all_individual_performance_audits_for_type?(with_tag)
      @audit.send(:"num_individual_performance_audits_#{with_tag ? :with_tag : :without_tag}_remaining") <= 0
    end

    def enqueue_individual_performance_audit_with_tag!
      AuditRunnerJobs::RunIndividualPerformanceAudit.perform_later(audit: @audit, perform_audit_with_tag: true)
    end

    def enqueue_individual_performance_audit_without_tag!
      AuditRunnerJobs::RunIndividualPerformanceAudit.perform_later(audit: @audit, perform_audit_with_tag: false)
    end

    def audit_reached_maximum_failed_performance_audits!
      err_msg = "Reached maximum performance audit retry count of #{@audit.maximum_individual_performance_audit_attempts}, stopping audit."
      Rails.logger.error err_msg
      @audit.performance_audit_error!(err_msg)
    end
  end
end