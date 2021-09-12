module PerformanceAuditManager
  class EvaluateIndividualResults
    attr_reader :individual_performance_audit
    def initialize(individual_performance_audit_id:, results:, logs:, error:)
      @results = results
      @error = error
      @logs = logs

      @individual_performance_audit = PerformanceAudit.includes(audit: [:tag_version, :tag]).find(individual_performance_audit_id)
    end

    def evaluate!
      # if @error || !validity_checker.valid?
      if @error
        update_individual_performance_audits_results_for_failed_audit!
        individual_performance_audit.error!(@error)
      else
        update_individual_performance_audits_results_for_successful_audit!
        individual_performance_audit.completed!
      end
    end

    private

    def update_individual_performance_audits_results_for_successful_audit!
      individual_performance_audit.update(
        dom_complete: @results['DOMComplete'],
        dom_interactive: @results['DOMInteractive'],
        first_contentful_paint: @results['FirstContentfulPaint'],
        layout_duration: @results['LayoutDuration'],
        script_duration: @results['ScriptDuration'],
        task_duration: @results['TaskDuration'],
        tagsafe_score: calculate_tagsafe_score_for_performance_audit,
        performance_audit_log_attributes: { logs: @logs }
      )
    end

    def update_individual_performance_audits_results_for_failed_audit!
      individual_performance_audit.update(
        dom_complete: -1,
        dom_interactive: -1,
        first_contentful_paint: -1,
        script_duration: -1,
        layout_duration: -1,
        task_duration: -1,
        tagsafe_score: -1,
        performance_audit_log_attributes: { logs: @logs }
      )
    end

    def calculate_tagsafe_score_for_performance_audit
      @tagsafe_score ||= TagSafeScorer.new(
        dom_complete: @results['DOMComplete'],
        dom_interactive: @results['DOMInteractive'],
        first_contentful_paint: @results['FirstContentfulPaint'],
        layout_duration: @results['LayoutDuration'],
        script_duration: @results['ScriptDuration'],
        task_duration: @results['TaskDuration'],
        byte_size: audit.tag_version.bytes
      ).score!
    end

    def audit
      @audit ||= individual_performance_audit.audit
    end

    # def validity_checker
    #   @validity_checker ||= PerformanceAuditManager::ValidityChecker.new(
    #     audited_tag_url: @audit.tag.full_url,
    #     results_with_tag: @results_with_tag, 
    #     results_without_tag: @results_without_tag
    #   )
    # end
  end
end