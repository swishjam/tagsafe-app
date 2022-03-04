module PerformanceAuditManager
  class QueueMaintainer
    def initialize(audit)
      @audit = audit
    end
    
    def enqueue_next_set_of_performance_audits_or_mark_as_completed!
      if @audit.reached_maximum_failed_performance_audits?
        @audit.performance_audit_error!("Reached maximum performance audit retry count of #{@audit.maximum_individual_performance_audit_attempts}, stopping audit.")
      elsif completed_performance_audit_based_on_config?
        @audit.performance_audit_completed!(tagsafe_score_confidence_range)
      elsif would_meet_completion_criteria_after_removing_outliers?
        outlier_identifier.mark_outliers!
        @audit.performance_audit_completed!(calculate_tagsafe_score_confidence_range!)
      elsif reached_maximum_total_successful_performance_audits?
        @audit.performance_audit_completed!(tagsafe_score_confidence_range)
      else
        generate_performance_audit_set!
        self.class.new(@audit).enqueue_next_set_of_performance_audits_or_mark_as_completed!
      end
    end

    private

    def generate_performance_audit_set!
      PerformanceAuditManager::PerformanceAuditSetGenerator.new(@audit).generate_performance_audit_set!
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
      end
      outlier_identifier.un_mark_any_marked_outliers!
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
      @audit.delta_performance_audits.count >= Flag.flag_value_for_objects(@audit.tag, @audit.tag.domain, slug: 'minimum_performance_audit_sets_to_meet_completion_criteria').to_i
    end

    def reached_required_tagsafe_score_confidence_range?
      tagsafe_score_confidence_range <= Flag.flag_value_for_objects(@audit.tag, @audit.tag.domain, slug: 'performance_audit_tagsafe_score_confidence_range_completion_criteria').to_i
    end

    def reached_maximum_total_successful_performance_audits?
      @audit.delta_performance_audits.count >= Flag.flag_value_for_objects(@audit.tag, @audit.tag.domain, slug: 'maximum_total_successful_performance_audit_sets').to_i
    end

    def tagsafe_score_confidence_range
      @tagsafe_score_confidence_range ||= calculate_tagsafe_score_confidence_range!
    end

    def calculate_tagsafe_score_confidence_range!
      @tagsafe_score_confidence_range = @audit.confidence_calculator.tagsafe_score_confidence_plus_minus
    end
  end
end