class JsUsageAuditComponent < AuditComponent
  include ActionView::Helpers::NumberHelper
  self.friendly_name = 'JS Usage'

  def perform_audit!
    AuditRunnerJobs::RunJsUsageCalculationJob.perform_later(self)
  end

  def explanation
    <<~MSG
      #{raw_results['percent_js_used'].round(2)}% of the #{audit.tag.try_friendly_name} javascript is used when loading the page 
      (#{number_to_human_size(raw_results['js_bytes_used'])} of #{number_to_human_size(raw_results['total_js_bytes'])}).
    MSG
  end
end