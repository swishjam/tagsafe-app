module PerformanceAuditManager
  class MedianPerformanceAuditsCreator
    def initialize(audit)
      @audit = audit
    end

    def find_and_apply_median_audits!
      calculated_median_delta_performance_audit.performance_audit_with_tag.update!(type: MedianIndividualPerformanceAudit.to_s)
      calculated_median_delta_performance_audit.performance_audit_without_tag.update!(type: MedianIndividualPerformanceAudit.to_s)
      calculated_median_delta_performance_audit.update!(type: MedianDeltaPerformanceAudit.to_s)
    end

    def calculated_median_delta_performance_audit
      @median_delta_performance_audit ||= begin
        count = @audit.individual_delta_performance_audits.count
        sorted_audits = @audit.individual_delta_performance_audits.order(tagsafe_score: :DESC)
        sorted_audits[count / 2]
      end
    end
  end
end