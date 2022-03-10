module PerformanceAuditManager
  class QueueMaintainer
    NUM_PERFORMANCE_AUDITS_TO_RUN_SIMULTANEOUSLY = 1
    
    def initialize(audit)
      @audit = audit
    end
    
    def run_next_set_of_performance_audits_or_mark_as_completed!
      if @audit.reached_maximum_failed_performance_audits?
        @audit.performance_audit_error!("Reached maximum performance audit retry count of #{@audit.maximum_individual_performance_audit_attempts}, stopping audit.")
      elsif completed_performance_audit_based_on_config?
        @audit.performance_audit_completed!(tagsafe_score_confidence_range)
      elsif would_meet_completion_criteria_after_removing_outliers?
        outlier_identifier.mark_outliers!
        @audit.performance_audit_completed!(calculate_tagsafe_score_confidence_range!)
      elsif reached_maximum_total_successful_performance_audits?
        reached_maximum_total_successful_performance_audits!
      else
        run_next_set_of_performance_audits!
      end
    end

    private

    def run_next_set_of_performance_audits!
      # TODO: cant run many performance audits at a time due to us calling `run_next_set_of_performance_audits_or_mark_as_completed!`
      # after every result, needs to be run after the batch of audits are complete
      # we can create a "batch identifier" so we can aggregate performance audits by batch and only run_next_set when entire batch is complete.
      NUM_PERFORMANCE_AUDITS_TO_RUN_SIMULTANEOUSLY.times do
        LambdaFunctionInvoker::PerformanceAuditer.new(audit: @audit, performance_audit_klass: IndividualPerformanceAuditWithTag).send!
        LambdaFunctionInvoker::PerformanceAuditer.new(audit: @audit, performance_audit_klass: IndividualPerformanceAuditWithoutTag).send!
      end
    end

    def outlier_identifier
      @outlier_identifier ||= PerformanceAuditManager::OutlierIdentifier.new(@audit)
    end

    def would_meet_completion_criteria_after_removing_outliers?
      return false unless outlier_identifier.has_minimum_delta_performance_audits_to_identify_outliers?
      meets_completion_criteria = false
      outliers = outlier_identifier.find_outliers!
      if outliers.any?
        tagsafe_score_confidence_range_before_outliers_marked = tagsafe_score_confidence_range
        outlier_identifier.mark_outliers!
        calculate_tagsafe_score_confidence_range!
        meets_completion_criteria = completed_performance_audit_based_on_config?
        outlier_identifier.un_mark_any_marked_outliers!
      end
      meets_completion_criteria
    end

    def completed_performance_audit_based_on_config?
      if @audit.performance_audit_configuration.completion_indicator_type == PerformanceAudit.CONFIDENCE_RANGE_COMPLETION_INDICATOR_TYPE
        completed_minimum_required_performance_audits? && reached_required_tagsafe_score_confidence_range?
      else
        @audit.delta_performance_audits.count >= @audit.performance_audit_configuration.num_performance_audits_to_run
      end
    end

    def completed_minimum_required_performance_audits?
      @audit.delta_performance_audits.count >= @audit.performance_audit_configuration.minimum_num_sets
    end

    def reached_required_tagsafe_score_confidence_range?
      tagsafe_score_confidence_range <= @audit.performance_audit_configuration.required_tagsafe_score_range
    end

    def reached_maximum_total_successful_performance_audits?
      @audit.delta_performance_audits.count >= @audit.performance_audit_configuration.maximum_num_sets
    end

    def reached_maximum_total_successful_performance_audits!
      if @audit.performance_audit_configuration.fail_when_confidence_range_not_met
        @audit.performance_audit_error!("Tagsafe Score confidence range is #{tagsafe_score_confidence_range} when it needed to be within #{@audit.performance_audit_configuration.required_tagsafe_score_range} after #{@audit.performance_audit_configuration.maximum_num_sets} performance audits")
      else
        @audit.performance_audit_completed!(tagsafe_score_confidence_range)
      end
    end

    def tagsafe_score_confidence_range
      @tagsafe_score_confidence_range ||= calculate_tagsafe_score_confidence_range!
    end

    def calculate_tagsafe_score_confidence_range!
      @tagsafe_score_confidence_range = @audit.confidence_calculator.tagsafe_score_confidence_plus_minus
    end
  end
end