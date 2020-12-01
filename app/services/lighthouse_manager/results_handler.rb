class LighthouseManager::ResultsHandler
  def initialize(error:, results_with_tag:, results_without_tag:, audit_id:)
    @error = error
    @audit_id = audit_id
    @results_without_tag = results_without_tag
    @results_with_tag = results_with_tag
  end

  def capture_results!
    if @error
      audit.lighthouse_error!(@error)
      # create an audit.retry method maybe? new audit reason ('Retry')? lighthouse errors shouldn't happen!
    else
      results_with_current_tag = capture_raw_results(CurrentTagLighthouseAudit, @results_with_tag)
      results_without_tag = capture_raw_results(WithoutTagLighthouseAudit, @results_without_tag)
      
      capture_average_results(AverageCurrentTagLighthouseAudit, results_with_current_tag.average_results)
      capture_average_results(AverageWithoutTagLighthouseAudit, results_without_tag.average_results)
      
      capture_delta_results(results_with_current_tag.average_results, results_without_tag.average_results)
      
      audit.completed_lighthouse_audits!
    end
  end

  private

  def audit
    @audit ||= Audit.find(@audit_id)
  end

  def script_subscriber
    @script_subscriber ||= audit.script_subscriber
  end

  def capture_raw_results(lighthouse_audit_type_class, results_array)
    results_with_tag = LighthouseManager::RawResultsHandler.new(
      audit: audit, 
      lighthouse_audit_type_class: lighthouse_audit_type_class, 
      array_of_results: results_array,
      should_capture_metrics: should_capture_lighthouse_metrics_for_individual_audits
    ).capture_results!
  end

  def capture_average_results(lighthouse_audit_type_class, average_results)
    average_results_with_tag = LighthouseManager::AverageResultsHandler.new(
      audit: audit, 
      lighthouse_audit_type_class: lighthouse_audit_type_class, 
      average_results: average_results
    ).capture_results!
  end

  def capture_delta_results(average_results_with_tag, average_results_without_tag)
    LighthouseManager::DeltaResultsHandler.new(
      audit: audit,
      average_results_with_tag: average_results_with_tag, 
      average_results_without_tag: average_results_without_tag
    ).capture_results!
  end

  def should_capture_lighthouse_metrics_for_individual_audits
    script_subscriber.lighthouse_preferences.should_capture_individual_audit_metrics
  end
end