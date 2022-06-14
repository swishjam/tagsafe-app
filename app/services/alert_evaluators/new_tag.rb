module AlertEvaluators
  class NewTag
    def initialize(tag)
      @tag = tag
    end

    def trigger_alerts_if_criteria_is_met!
      new_tag_alert_configurations_for_domain.each do |alert_config|
        alert_config.triggered_alerts.create!(initiating_record: @tag, tag: @tag)
      end
    end

    private

    def new_tag_alert_configurations_for_domain
      @new_tag_alert_configurations_for_domain ||= @tag.domain.alert_configurations.enabled_for_all_tags.by_klass(NewTagAlertConfiguration)
    end
  end
end