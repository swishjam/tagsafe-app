module AlertEvaluators
  class PerformanceAuditExceededThreshold < Base
    def initialize(audit)
      @audit = audit
      @tag = audit.tag
    end

    def trigger_alerts_if_criteria_is_met!
      exceeded_threshold_alert_configurations.each do |alert_config| 
        alert_config.triggered_alerts.create!(initiating_record: @audit, tag: @tag)
      end
    end
    
    private

    def exceeded_threshold_alert_configurations
      return @exceeded_threshold_alert_configurations if defined?(@exceeded_threshold_alert_configurations)
      @exceeded_threshold_alert_configurations = []
      return @exceeded_threshold_alert_configurations if @audit.performance_audit_failed?
      alert_configurations_for_tag_and_domain.each do |alert_configuration|
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
  end
end