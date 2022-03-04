module PerformanceAuditManager
  class DeltaPerformanceAuditCreator
    def initialize(
      performance_audit_with_tag:, 
      performance_audit_without_tag:, 
      delta_performance_audit_klass: IndividualDeltaPerformanceAudit
    )
      @performance_audit_with_tag = performance_audit_with_tag
      @performance_audit_without_tag = performance_audit_without_tag
      @delta_performance_audit_klass = delta_performance_audit_klass
    end

    def create_delta_performance_audit!
      @delta_performance_audit_klass.create!(formatted_delta_results)
    end

    private

    def formatted_delta_results
      delta_metrics = {
        dom_complete_delta: delta_between(:dom_complete),
        dom_content_loaded_delta: delta_between(:dom_content_loaded),
        dom_interactive_delta: delta_between(:dom_interactive),
        first_contentful_paint_delta: delta_between(:first_contentful_paint),
        script_duration_delta: delta_between(:script_duration),
        task_duration_delta: delta_between(:task_duration),
        layout_duration_delta: delta_between(:layout_duration)
      }
      delta_metrics.merge!({
        is_outlier: false,
        tagsafe_score: tagsafe_score_from_delta_results(delta_metrics),
        performance_audit_with_tag: @performance_audit_with_tag,
        performance_audit_without_tag: @performance_audit_without_tag,
        audit: @performance_audit_without_tag.audit
      })
    end

    def delta_between(column)
      delta = @performance_audit_with_tag.send(column) - @performance_audit_without_tag.send(column)
      delta < 0 ? 0.0 : delta
    rescue => e
      raise StandardError, "Cannot calculate delta for #{column} between performance audits #{@performance_audit_without_tag.uid} and #{@performance_audit_with_tag.uid}: #{e}"
    end

    def tagsafe_score_from_delta_results(results)
      TagsafeScorer.new({ 
        performance_audit_calculator: @performance_audit_without_tag.audit.tag.domain.current_performance_audit_calculator,
        byte_size: @performance_audit_without_tag.audit.tag_version.bytes 
      }.merge(results)).score!
    end
  end
end