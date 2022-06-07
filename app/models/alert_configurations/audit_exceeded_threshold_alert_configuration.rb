class AuditExceededThresholdAlertConfiguration < AlertConfiguration
  self.trigger_rule_fields = %i[threshold_value threshold_metric]
  self.user_facing_alert_name = 'Audit Exceeded Threshold'

  def has_acceptable_trigger_rules_validation
    unless trigger_rule_fields.threshold_value.present? &&
      trigger_rule_fields.threshold_metric.present? &&
      %w[
        dom_complete_impact 
        dom_interactive_impact 
        main_thread_execution_ms_impact
      ].includes?(trigger_rule_fields.threshold_metric)
      errors.add(:base, "Invalid trigger rules, it must include a valid threshold value and threshold metric")
    end
  end
end