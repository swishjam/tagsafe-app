module AlertEvaluators
  class NewTagVersion < Base
    def initialize(tag_version)
      @tag_version = tag_version
      @tag = tag_version.tag
    end

    def trigger_alerts_if_criteria_is_met!
      return if @tag_version.first_version?
      alert_configurations_for_tag_and_domain.each do |alert_config|
        alert_config.triggered_alerts.create!(initiating_record: @tag_version, tag: @tag_version.tag)
      end
    end
  end
end