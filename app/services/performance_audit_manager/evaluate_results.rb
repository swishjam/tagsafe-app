module PerformanceAuditManager
  class EvaluateResults
    def initialize(error:, results_with_tag:, results_without_tag:, audit_id:, num_attempts: 1)
      @audit = Audit.includes(tag_version: :tag).find(audit_id)
      @error = error
      @results_with_tag = results_with_tag
      @results_without_tag = results_without_tag
      @num_attempts = num_attempts
    end

    def evaluate!
      if @error || !validity_checker.valid?
        capture_invalid_performance_audit!
      else
        capture_valid_performance_audit!
      end
    end

    private

    def capture_invalid_performance_audit!
      @audit.performance_audit_error!(@error || validity_checker.invalid_reason, @num_attempts)
      capture_logs_for_failed_audit(PerformanceAuditWithTag, @results_with_tag['logs'])
      capture_logs_for_failed_audit(PerformanceAuditWithoutTag, @results_without_tag['logs'])
    end

    def capture_valid_performance_audit!
      capture_results(PerformanceAuditWithTag, median_results_with_tag, @results_with_tag['logs'])
      capture_results(PerformanceAuditWithoutTag, median_results_without_tag, @results_without_tag['logs'])
      capture_delta_performance_audit!
      @audit.completed_performance_audit!
    end

    def median_results_with_tag
      @median_results_with_tag ||= get_median_result(@results_with_tag['performance_results'])
    end

    def median_results_without_tag
      @median_results_without_tag ||= get_median_result(@results_without_tag['performance_results'])
    end

    def validity_checker
      @validity_checker ||= PerformanceAuditManager::ValidityChecker.new(
        audited_tag_url: @audit.tag.full_url,
        results_with_tag: @results_with_tag, 
        results_without_tag: @results_without_tag
      )
    end

    def get_median_result(result_set)
      score_dictionary = {}
      scores = []
      result_set.each do |result|
        score = calculate_tagsafe_score_for_result_set(result)
        scores << score
        score_dictionary[score] = result
      end
      sorted_scores = scores.sort
      num_of_results = sorted_scores.count
      # when the num of results are even, take the lowest score of the two median values. Is there a better way to do find the most accurate of the two scores?
      median_score = num_of_results % 2 == 0 ? sorted_scores[(num_of_results/2).floor-1] : sorted_scores[(num_of_results/2).floor]
      score_dictionary[median_score]
    end

    def capture_results(performance_audit_type_klass, results, logs = nil)
      perf_audit = performance_audit_type_klass.create(
        audit: @audit,
        dom_complete: results['DOMComplete'],
        dom_interactive: results['DOMInteractive'],
        first_contentful_paint: results['FirstContentfulPaint'],
        layout_duration: results['LayoutDuration'],
        script_duration: results['ScriptDuration'],
        task_duration: results['TaskDuration'],
        tagsafe_score: results['TagSafeScore']
      )
      PerformanceAuditLog.create(logs: logs, performance_audit: perf_audit) unless logs.nil?
      perf_audit
    end

    def capture_delta_performance_audit!
      delta_results['TagSafeScore'] = calculate_tagsafe_score_for_result_set(delta_results)
      capture_results(DeltaPerformanceAudit, delta_results)
    end

    def capture_logs_for_failed_audit(performance_audit_klass, logs)
      performance_audit = performance_audit_klass.create(
        audit: @audit,
        dom_complete: -1,
        dom_interactive: -1,
        first_contentful_paint: -1,
        script_duration: -1,
        layout_duration: -1,
        task_duration: -1,
        tagsafe_score: -1
      )
      PerformanceAuditLog.create(logs: logs, performance_audit: performance_audit)
    end

    def calculate_tagsafe_score_for_result_set(result)
      TagSafeScorer.new(
        dom_complete: result['DOMComplete'],
        dom_interactive: result['DOMInteractive'],
        first_contentful_paint: result['FirstContentfulPaint'],
        layout_duration: result['LayoutDuration'],
        script_duration: result['ScriptDuration'],
        task_duration: result['TaskDuration'],
        byte_size: @audit.tag_version.bytes
      ).score!
    end

    def delta_results
      @delta_results ||= PerformanceAuditManager::DeltaCalculator.new(
        results_with_tag: median_results_with_tag, 
        results_without_tag: median_results_without_tag
      ).calculate!
    end
  end
end