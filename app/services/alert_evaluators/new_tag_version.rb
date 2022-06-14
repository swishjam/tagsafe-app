module AlertEvaluators
  class NewTagVersion
    def initialize(tag_version)
      @tag_version = tag_version
    end

    def trigger_alerts_if_criteria_is_met!
      alert_configurations_for_tag.each do |alert_config|
        alert_config.triggered_alerts.create!(initiating_record: @tag_version, tag: @tag_version.tag)
      end
    end

    private

    def alert_configurations_for_tag
      @alert_configurations_for_tag ||= begin
        alert_configs_for_tag = @tag_version.tag.alert_configurations.not_enabled_for_all_tags.by_klass(NewTagVersionAlertConfiguration)
        alert_configs_for_domain = @tag_version.tag.domain.alert_configurations.enabled_for_all_tags.by_klass(NewTagVersionAlertConfiguration)
        alert_configs_for_tag.to_a.concat(alert_configs_for_domain.to_a)
      end
    end
  end
end