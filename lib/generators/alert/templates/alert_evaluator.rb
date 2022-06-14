module AlertEvaluators
  class <%= class_name %>
    def initialize(audit)
      @audit = audit
    end

    def trigger_alerts_if_criteria_is_met!
      alert_configurations_that_meet_criteria.each do |alert_config| 
        alert_config.triggered_alerts.create!(initiating_record: @audit, tag: @audit.tag)
      end
    end

    private

    def alert_configurations_that_meet_criteria
    end
  end