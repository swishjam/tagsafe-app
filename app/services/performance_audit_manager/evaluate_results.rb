module PerformanceAuditManager
  class EvaluateResults
    def initialize(error:, results_with_tag:, results_without_tag:, audit_id:, with_tag_logs:, without_tag_logs:, num_attempts: 1)
      @audit = Audit.find(audit_id)
      @error = error
      @results_with_tag = results_with_tag
      @results_without_tag = results_without_tag
      @with_tag_logs = with_tag_logs
      @without_tag_logs = without_tag_logs
      @num_attempts = num_attempts
    end

    def evaluate!
      if @error
        @audit.performance_audit_error!(@error, @num_attempts)
      else
        capture_results(PerformanceAuditWithTag, @results_with_tag, @with_tag_logs)
        capture_results(PerformanceAuditWithoutTag, @results_without_tag, @without_tag_logs)
        capture_delta_performance_audit!
        @audit.completed_performance_audit!
      end
    end

    private

    def capture_results(performance_audit_type_klass, results, logs = nil)
      perf_audit = performance_audit_type_klass.create(
        audit: @audit,
        dom_complete: results['DOMComplete'],
        dom_interactive: results['DOMInteractive'],
        first_contentful_paint: results['FirstContentfulPaint'],
        layout_duration: results['LayoutDuration'],
        script_duration: results['ScriptDuration'],
        task_duration: results['TaskDuration']
      )
      PerformanceAuditLog.create(logs: logs, performance_audit: perf_audit) unless logs.nil?
      perf_audit
    end

    def capture_delta_performance_audit!
      delta_performance_audit = capture_results(DeltaPerformanceAudit, delta_results)
      TagSafeScorer.new(delta_performance_audit).record_score!
    end

    def delta_results
      @delta_results ||= PerformanceAuditManager::DeltaCalculator.new(
        results_with_tag: @results_with_tag, 
        results_without_tag: @results_without_tag
      ).calculate!
    end
  end
end