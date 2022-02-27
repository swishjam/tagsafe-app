module PerformanceAuditManager
  class DeltaPerformanceAuditsCreator
    def initialize(audit)
      @audit = audit
    end

    def create_delta_performance_audits!
      create_delta_performance_audit_for_individual_performance_audits!
      create_delta_performance_audit_for_average_performance_audits!
    end

    private

    def create_delta_performance_audit_for_individual_performance_audits!
      without_tag_audits = @audit.individual_performance_audits_without_tag.most_recent_first.to_a
      with_tag_audits = @audit.individual_performance_audits_with_tag.most_recent_first.to_a\
      if without_tag_audits.count != with_tag_audits.count
        Rails.logger.warn "Audit #{@audit.uid} has an uneven amount of performance audits with and without tag"
      end
      with_tag_audits.each_with_index do |with_tag_audit, i|
        without_tag_audit = without_tag_audits[i]
        unless without_tag_audit.nil?
          IndividualDeltaPerformanceAudit.create!(
            calculate_and_format_delta_results_for(with_tag_audit, without_tag_audit)
          )
        end
      end
    end

    def create_delta_performance_audit_for_average_performance_audits!
      AverageDeltaPerformanceAudit.create!(
        calculate_and_format_delta_results_for(@audit.average_performance_audit_with_tag, @audit.average_performance_audit_without_tag)
      )
    end

    def calculate_and_format_delta_results_for(with_tag_performance_audit, without_tag_performance_audit)
      delta_metrics = {
        dom_complete_delta: delta_between(:dom_complete, with_tag_performance_audit, without_tag_performance_audit),
        dom_content_loaded_delta: delta_between(:dom_content_loaded, with_tag_performance_audit, without_tag_performance_audit),
        dom_interactive_delta: delta_between(:dom_interactive, with_tag_performance_audit, without_tag_performance_audit),
        first_contentful_paint_delta: delta_between(:first_contentful_paint, with_tag_performance_audit, without_tag_performance_audit),
        script_duration_delta: delta_between(:script_duration, with_tag_performance_audit, without_tag_performance_audit),
        task_duration_delta: delta_between(:task_duration, with_tag_performance_audit, without_tag_performance_audit),
        layout_duration_delta: delta_between(:layout_duration, with_tag_performance_audit, without_tag_performance_audit)
      }
      delta_metrics.merge!({
        tagsafe_score: tagsafe_score_from_delta_results(delta_metrics),
        performance_audit_with_tag: with_tag_performance_audit,
        performance_audit_without_tag: without_tag_performance_audit,
        audit: @audit
      })
    end

    def delta_between(column, with_tag_performance_audit, without_tag_performance_audit)
      delta = with_tag_performance_audit.send(column) - without_tag_performance_audit.send(column)
      delta < 0 ? 0.0 : delta
    rescue => e
      raise StandardError, "Cannot calculate delta for #{column} on audit #{@audit.uid}: #{e}"
    end

    def tagsafe_score_from_delta_results(results)
      TagsafeScorer.new({ 
        performance_audit_calculator: @audit.tag.domain.current_performance_audit_calculator,
        byte_size: @audit.tag_version.bytes 
      }.merge(results)).score!
    end
  end
end