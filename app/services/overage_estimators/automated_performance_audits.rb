module OverageEstimators
  class AutomatedPerformanceAudits
    COST_PER_AUTOMATED_PERFORMANCE_AUDIT_IN_DOLLARS = 0.05
    
    def initialize(domain:, tag:, new_scheduled_audit_interval:)
      @domain = domain
      @tag = tag
      @new_scheduled_audit_interval = new_scheduled_audit_interval.to_i
    end

    def price_would_increase?
      return false if @new_scheduled_audit_interval.zero?
      @new_scheduled_audit_interval < @tag.tag_preferences.scheduled_audit_minute_interval
    end

    def would_exceed_included_usage_for_subscription_package?
      return false if @new_scheduled_audit_interval.zero?
      expected_total_usage_next_month_on_proposed_config > 0
    end

    def expected_total_usage_next_month_on_current_config
      @expected_total_usage_next_month_on_current_config ||= begin
        num_scheduled_audits_next_month = 0
        @domain.tags.scheduled_audits_enabled.each do |tag|
          num_scheduled_audits_next_month += minutes_in_next_month / tag.tag_preferences.scheduled_audit_minute_interval
        end
        num_scheduled_audits_next_month.ceil
      end
    end

    def expected_dollar_overage_next_month_on_current_config
      (expected_total_usage_next_month_on_current_config - automated_audits_included_in_package) * COST_PER_AUTOMATED_PERFORMANCE_AUDIT_IN_DOLLARS
    end

    def expected_total_usage_next_month_on_proposed_config
      @potential_additional_automated_audits_next_month_on_new_interval ||= begin
        num_scheduled_audits_next_month = expected_total_usage_next_month_on_current_config
        num_scheduled_audits_next_month -= (minutes_in_next_month / @tag.tag_preferences.scheduled_audit_minute_interval).ceil
        num_scheduled_audits_next_month += minutes_in_next_month / @new_scheduled_audit_interval
        num_scheduled_audits_next_month.ceil
      end 
    end

    def expected_dollar_overage_next_month_on_proposed_config
      return 0 unless would_exceed_included_usage_for_subscription_package?
      (expected_total_usage_next_month_on_proposed_config - automated_audits_included_in_package) * COST_PER_AUTOMATED_PERFORMANCE_AUDIT_IN_DOLLARS
    end

    def cost_of_proposed_changes
      return 0 unless would_exceed_included_usage_for_subscription_package?
      expected_dollar_overage_next_month_on_proposed_config - expected_dollar_overage_next_month_on_current_config
    end

    private

    def automated_audits_included_in_package
      @automated_audits_included_in_package ||= @domain.subscription_feature_restriction.automated_performance_audits_included_per_month
    end

    def minutes_in_next_month
      (Time.current.next_month.end_of_month - Time.current.next_month.beginning_of_month) / 1.minute
    end
  end
end