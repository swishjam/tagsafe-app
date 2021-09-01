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
      inject_tagsafe_score_for_performance_audits
      create_performance_audit_with_tag!
      create_performance_audit_without_tag!
      create_delta_performance_audit!
      @audit.completed_performance_audit!
    end

    def median_results_with_tag
      @median_results_with_tag ||= get_median_performance_audit(@results_with_tag['performance_results'], with_tag: true)
    end

    def median_results_without_tag
      @median_results_without_tag ||= get_median_performance_audit(@results_without_tag['performance_results'], with_tag: false)
    end

    def validity_checker
      @validity_checker ||= PerformanceAuditManager::ValidityChecker.new(
        audited_tag_url: @audit.tag.full_url,
        results_with_tag: @results_with_tag, 
        results_without_tag: @results_without_tag
      )
    end

    def inject_tagsafe_score_for_performance_audits
      @results_with_tag['performance_results'].each{ |result| result['TagSafeScore'] = calculate_tagsafe_score_for_performance_audit(result) }
      @results_without_tag['performance_results'].each{ |result| result['TagSafeScore'] = calculate_tagsafe_score_for_performance_audit(result) }
    end

    def get_median_performance_audit(performance_audits, with_tag:)
      tagsafe_score_results_map = {}
      tagsafe_scores = []
      performance_audits.each do |audit_result|
        create_performance_audit(
          performance_audit_class: with_tag ? IndividualPerformanceAuditWithTag : IndividualPerformanceAuditWithoutTag, 
          performance_audit_results: audit_result
        ) if @audit.capture_individual_performance_audits?
        tagsafe_scores << audit_result['TagSafeScore']
        tagsafe_score_results_map[audit_result['TagSafeScore']] = audit_result
      end
      sorted_tagsafe_scores = tagsafe_scores.sort
      num_of_performance_audits = sorted_tagsafe_scores.count
      # when the num of results are even, take the lowest score of the two median values. Is there a better way to do find the most accurate of the two scores?
      median_tagsafe_score = num_of_performance_audits % 2 == 0 ? sorted_tagsafe_scores[(num_of_performance_audits/2).floor-1] : sorted_tagsafe_scores[(num_of_performance_audits/2).floor]
      tagsafe_score_results_map[median_tagsafe_score]
    end

    def create_performance_audit(performance_audit_class:, performance_audit_results:, std_dev: nil, logs: nil)
      perf_audit = performance_audit_class.create(
        audit: @audit,
        dom_complete: performance_audit_results['DOMComplete'],
        dom_interactive: performance_audit_results['DOMInteractive'],
        first_contentful_paint: performance_audit_results['FirstContentfulPaint'],
        layout_duration: performance_audit_results['LayoutDuration'],
        script_duration: performance_audit_results['ScriptDuration'],
        task_duration: performance_audit_results['TaskDuration'],
        tagsafe_score: performance_audit_results['TagSafeScore'],
        tagsafe_score_standard_deviation: std_dev,
        performance_audit_logs_attributes: { logs: logs }
      )
    end

    def create_performance_audit_with_tag!
      create_performance_audit(
        performance_audit_class: PerformanceAuditWithTag, 
        performance_audit_results: median_results_with_tag, 
        std_dev: Statistics.std_dev(@results_with_tag['performance_results'].collect{ |performance_audit_result| performance_audit_result['TagSafeScore'] }),
        logs: @results_with_tag['logs']
      )
    end

    def create_performance_audit_without_tag!
      create_performance_audit(
        performance_audit_class: PerformanceAuditWithoutTag, 
        performance_audit_results: median_results_without_tag, 
        std_dev: Statistics.std_dev(@results_without_tag['performance_results'].collect{ |performance_audit_result| performance_audit_result['TagSafeScore'] }),
        logs: @results_without_tag['logs']
      )
    end

    def create_delta_performance_audit!
      delta_results['TagSafeScore'] = calculate_tagsafe_score_for_performance_audit(delta_results)
      create_performance_audit(performance_audit_class: DeltaPerformanceAudit, performance_audit_results: delta_results)
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
        tagsafe_score: -1,
        performance_audit_logs_attributes: { logs: logs }
      )
    end

    def calculate_tagsafe_score_for_performance_audit(result)
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