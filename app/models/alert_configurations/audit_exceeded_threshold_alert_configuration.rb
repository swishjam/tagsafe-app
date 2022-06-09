class AuditExceededThresholdAlertConfiguration < AlertConfiguration
  self.trigger_rule_fields = %i[exceeded_metric operator exceeded_metric_value]
  self.user_facing_alert_name = 'Audit exceeded threshold'

  serialize :trigger_rules, Serializers::AlertTriggerRules::AuditExceededThreshold

  def trigger_rules_description
    "The alert will trigger whenever a tag's #{trigger_rules.human_exceeded_metric} is #{trigger_rules.human_operator} #{trigger_rules.human_exceeded_metric_value}"
  end

  def emit_alert_triggered_notifications(triggered_alert)
    domain_users.each do |domain_user|
      send_alert_email(domain_user.user, triggered_alert)
      broadcast_notification(domain_user.user, triggered_alert)
    end
  end

  def triggered_alert_description(triggered_alert)
    "Your #{triggered_alert.tag.try_friendly_name} now has a #{trigger_rules.human_exceeded_metric} of #{trigger_rules.human_exceeded_metric_value}, exceeding your threshold of #{trigger_rules.human_exceeded_metric_value}."
  end

  private

  def send_alert_email(user, triggered_alert)
    TagsafeEmail::AuditExceededThresholdAlert.new(
      user: user, 
      audit: triggered_alert.initiating_record,
      alert_configuration: self
    ).send!
  end

  def broadcast_notification(user, triggered_alert)
    user.broadcast_notification(
      title: "🚨 #{name} 🚨",
      partial: 'alert_configurations/audit_exceeded_threshold_notification', 
      partial_locals: { 
        tag: triggered_alert.tag, 
        audit: triggered_alert.initiating_record, 
        alert_configuration: self,
        triggered_alert: triggered_alert
      }
    )
  end

  def has_acceptable_trigger_rules_validation
    unless trigger_rules.exceeded_metric_value.present? &&
      %w[
        tagsafe_score
        dom_complete_impact 
        dom_interactive_impact 
        main_thread_execution_ms_impact
      ].include?(trigger_rules.exceeded_metric) && 
      %w[less_than greater_than].include?(trigger_rules.operator)
      errors.add(:base, "Invalid trigger rules, it must include a valid threshold value and threshold metric")
    end
  end
end