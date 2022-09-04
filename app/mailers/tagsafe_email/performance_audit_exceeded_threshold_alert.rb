module TagsafeEmail
  class PerformanceAuditExceededThresholdAlert < Base
    self.sendgrid_template_id = :'d-f6a83a79f43f4742a78aebfedc0e4f89'
    self.from_email = :'alerts@tagsafe.io'

    def initialize(user:, alert_configuration:, initiating_record:, triggered_alert:)
      audit = initiating_record
      @to_email = user.email
      @template_variables = {
        domain_url: audit.domain.url_hostname,
        tag_name: audit.tag.try_friendly_name,
        alert_name: alert_configuration.name,
        actual_metric_value: audit.preferred_delta_performance_audit.send(alert_configuration.trigger_rules.exceeded_metric),
        previous_actual_metric_value: audit.audit_to_compare_with&.preferred_delta_performance_audit&.send(alert_configuration.trigger_rules.exceeded_metric),
        exceeded_metric: alert_configuration.trigger_rules.human_exceeded_metric,
        exceeded_metric_value: alert_configuration.trigger_rules.human_exceeded_metric_value,
        execution_reason: audit.execution_reason.name,
        audit_url: mail_safe_url("/tag/#{audit.tag.uid}/audits/#{audit.uid}?_domain_uid=#{audit.domain.uid}")
      }
    end
  end
end