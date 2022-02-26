module PerformanceAuditManager
  class AveragePerformanceAuditsCreator
    def initialize(audit)
      @audit = audit
    end

    def create_average_performance_audits!
      AveragePerformanceAudit.create!(
        avg_perf_audit_attrs(@audit.individual_performance_audits_with_tag.completed_successfully).merge!(audit_performed_with_tag: true)
      )
      AveragePerformanceAudit.create!(
        avg_perf_audit_attrs(@audit.individual_performance_audits_without_tag.completed_successfully).merge!(audit_performed_with_tag: false)
      )
    end

    private

    def avg_perf_audit_attrs(individual_performance_audits)
      {
        audit: @audit,
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