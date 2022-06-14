module AlertEvaluators
  class PerformanceAuditExceededThreshold
    def initialize(audit)
      @audit = audit
    end

    def trigger_alerts_if_criteria_is_met!
      exceeded_threshold_alert_configurations.each do |alert_config| 
        alert_config.triggered_alerts.create!(initiating_record: @audit, tag: @audit.tag)
      end
    end
    
    private

    def exceeded_threshold_alert_configurations
      return @exceeded_threshold_alert_configurations if defined?(@exceeded_threshold_alert_configurations)
      @exceeded_threshold_alert_configurations = []
      return @exceeded_threshold_alert_configurations if @audit.performance_audit_failed?
      audit_exceeded_threshold_alert_configurations_for_audited_tag.each do |alert_configuration|
        @exceeded_threshold_alert_configurations << alert_configuration if exceeded_alert_threshold?(alert_configuration)
      end
      @exceeded_threshold_alert_configurations
    end

    def exceeded_alert_threshold?(alert_configuration)
      audits_metric = @audit.preferred_delta_performance_audit[alert_configuration.trigger_rules.exceeded_metric]
      threshold = alert_configuration.trigger_rules.exceeded_metric_value
      if alert_configuration.trigger_rules.operator == 'less_than'
        audits_metric < threshold
      elsif alert_configuration.trigger_rules.operator == 'greater_than'
        audits_metric > threshold
      end
    end

    def audit_exceeded_threshold_alert_configurations_for_audited_tag
      @alert_configurations ||= begin 
        alert_configs_for_tag = @audit.tag.alert_configurations.not_enabled_for_all_tags.by_klass(PerformanceAuditExceededThresholdAlertConfiguration)
        alert_configs_for_domain = @audit.domain.alert_configurations.enabled_for_all_tags.by_klass(PerformanceAuditExceededThresholdAlertConfiguration)
        alert_configs_for_tag.to_a.concat(alert_configs_for_domain.to_a)
      end
    end
  end
end