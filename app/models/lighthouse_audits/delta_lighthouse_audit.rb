class DeltaLighthouseAudit < LighthouseAudit
  
  # percent change = (original value - new value)/original value
  def performance_score_percent_change
    return 0.0 unless lighthouse_audit.previous_succesful_lighthouse_audit.present?
    prev_score = lighthouse_audit.previous_succesful_lighthouse_audit.lighthouse_audit_results.by_audit_type(lighthouse_audit_type).first.formatted_performance_score
    (((prev_score - formatted_performance_score)/prev_score)*100).round(2)
  end
end