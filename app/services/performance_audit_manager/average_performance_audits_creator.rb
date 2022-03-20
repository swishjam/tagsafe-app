module PerformanceAuditManager
  class AveragePerformanceAuditsCreator
    def initialize(audit_or_domain_audit)
      @audit_or_domain_audit = audit_or_domain_audit
    end

    def create_average_performance_audits!
      average_performance_audit_with_tag = AveragePerformanceAuditWithTag.create!(
        avg_perf_audit_attrs(@audit_or_domain_audit.individual_performance_audits_with_tag.completed_successfully)
      )
      average_performance_audit_without_tag = AveragePerformanceAuditWithoutTag.create!(
        avg_perf_audit_attrs(@audit_or_domain_audit.individual_performance_audits_without_tag.completed_successfully)
      )
      PerformanceAuditManager::DeltaPerformanceAuditCreator.new(
        performance_audit_with_tag: average_performance_audit_with_tag,
        performance_audit_without_tag: average_performance_audit_without_tag,
        delta_performance_audit_klass: AverageDeltaPerformanceAudit
      ).create_delta_performance_audit!
    end

    private

    def avg_perf_audit_attrs(individual_performance_audits)
      {
        audit: @audit_or_domain_audit.is_a?(Audit) ? @audit_or_domain_audit : nil,
        domain_audit: @audit_or_domain_audit.is_a?(DomainAudit) ? @audit_or_domain_audit : nil,
        dom_complete: average_for(:dom_complete, individual_performance_audits),
        dom_content_loaded: average_for(:dom_content_loaded, individual_performance_audits),
        dom_interactive: average_for(:dom_interactive, individual_performance_audits),
        first_contentful_paint: average_for(:first_contentful_paint, individual_performance_audits),
        script_duration: average_for(:script_duration, individual_performance_audits),
        layout_duration: average_for(:layout_duration, individual_performance_audits),
        task_duration: average_for(:task_duration, individual_performance_audits),
        completed_at: Time.now
      }
    end

    def average_for(metric, individual_performance_audits)
      MathHelpers::Statistics.mean individual_performance_audits.collect(&:"#{metric}")
    rescue => e
      raise StandardError, "Unable to calculate the average for #{metric}: #{e.message}"
    end
  end
end