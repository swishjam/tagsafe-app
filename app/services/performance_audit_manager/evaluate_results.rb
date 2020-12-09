module PerformanceAuditManager
  class EvaluateResults
    def initialize(error:, results_with_tag:, results_without_tag:, audit_id:, with_tag_logs:, without_tag_logs:)
      @audit = Audit.find(audit_id)
      @error = error
      @results_with_tag = results_with_tag
      @results_without_tag = results_without_tag
      @with_tag_logs = with_tag_logs
      @without_tag_logs = without_tag_logs
    end

    def evaluate!
      if @error
        @audit.performance_audit_error!(@error)
      else
        capture_results(PerformanceAuditWithTag, @results_with_tag, @with_tag_logs)
        capture_results(PerformanceAuditWithoutTag, @results_without_tag, @without_tag_logs)
        capture_results(DeltaPerformanceAudit, delta_results)
        @audit.completed_performance_audit!
      end
    end

    private

    def capture_results(performane_audit_type_klass, results, logs = nil)
      perf_audit = performane_audit_type_klass.create(audit: @audit)
      PerformanceAuditLog.create(logs: logs, performance_audit: perf_audit) unless logs.nil?
      results.each{ |metric_key, result| capture_result_metric(perf_audit, metric_key, result) }
    end

    def capture_result_metric(performance_audit, metric_key, result)
      metric_type = PerformanceAuditMetricType.find_by(key: metric_key)
      if metric_type
        performance_audit.performance_audit_metrics.create(result: result, performance_audit_metric_type: metric_type)
      else
        Resque.logger.error "No PerformanceAuditMetricType with key #{metric_key}"
      end
    end

    def delta_results
      @delta_results ||= PerformanceAuditManager::DeltaCalculator.new(
        results_with_tag: @results_with_tag, 
        results_without_tag: @results_without_tag
      ).calculate!
    end
  end
end