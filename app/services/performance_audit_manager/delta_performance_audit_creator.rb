module PerformanceAuditManager
  class DeltaPerformanceAuditCreator
    def initialize(audit)
      @audit = audit
      set_performance_audits_used_for_scoring!
    end

    def create_delta_audit!
      DeltaPerformanceAudit.create!(calculate_and_format_delta_results)
    end

    private

    def calculate_and_format_delta_results
      delta_metrics = {
        dom_complete: delta_between(:dom_complete),
        dom_content_loaded: delta_between(:dom_content_loaded),
        dom_interactive: delta_between(:dom_interactive),
        first_contentful_paint: delta_between(:first_contentful_paint),
        script_duration: delta_between(:script_duration),
        task_duration: delta_between(:task_duration),
        layout_duration: delta_between(:layout_duration)
      }
      delta_metrics.merge!({
        tagsafe_score: tagsafe_score_from_delta_results(delta_metrics),
        audit: @audit
      })
    end

    def delta_between(column)
      delta = @median_individual_audit_with_tag.send(column) - @median_individual_audit_without_tag.send(column)
      delta < 0 ? 0.0 : delta
    end

    def tagsafe_score_from_delta_results(results)
      TagSafeScorer.new({ 
        performance_audit_calculator: @audit.tag.domain.current_performance_audit_calculator,
        byte_size: @audit.tag_version.bytes 
      }.merge(results)).score!
    end

    def set_performance_audits_used_for_scoring!
      median_individual_audit_with_tag = get_median_perf_audit(@audit.individual_performance_audits_with_tag.completed_successfully)
      median_individual_audit_without_tag = get_median_perf_audit(@audit.individual_performance_audits_without_tag.completed_successfully)
      median_individual_audit_with_tag.update!(used_for_scoring: true)
      median_individual_audit_without_tag.update!(used_for_scoring: true)
      @median_individual_audit_with_tag = median_individual_audit_with_tag
      @median_individual_audit_without_tag = median_individual_audit_without_tag
    end

    def get_median_perf_audit(performance_audits)
      count = performance_audits.count
      sorted_audits = performance_audits.order(tagsafe_score: :DESC)
      sorted_audits[count / 2]
    end
  end
end