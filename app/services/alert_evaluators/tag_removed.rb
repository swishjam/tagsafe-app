module AlertEvaluators
  class TagRemoved < Base
    def initialize(tag)
      @tag = tag
    end

    def trigger_alerts_if_criteria_is_met!
      alert_configurations_for_tag_and_container.each do |alert_config|
        alert_config.triggered_alerts.create!(initiating_record: @tag, tag: @tag)
      end
    end
  end
end