module AlertEvaluators
  class FunctionalTestSuiteFailed < Base
    def initialize(audit)
      @audit = audit
      @tag = audit.tag
    end

    def trigger_alerts_if_criteria_is_met!
      return false if @audit.passed_all_functional_tests?
      alert_configurations_for_tag_and_domain.each do |alert_config| 
        alert_config.triggered_alerts.create!(initiating_record: @audit, tag: @tag)
      end
    end
  end
end