module OverageEstimators
  class UptimeChecks
    COST_PER_UPTIME_CHECK_IN_DOLLARS = 0.001

    def initialize(domain)
      @domain = domain
    end

    def price_would_increase?
      true # assume this is only used on creating new UptimeRegionToCheck, not on destroy, so it always increases in price
    end

    def would_exceed_included_usage_for_subscription_package?
      expected_total_usage_next_month_on_proposed_config > uptime_checks_included_in_subscription_package
    end

    def expected_total_usage_next_month_on_current_config
      @expected_total_usage_next_month_on_current_config ||= ((@domain.uptime_regions_to_check.count * minutes_in_next_month) + minutes_in_next_month).ceil
    end

    def expected_dollar_overage_next_month_on_current_config
      expected_total_usage_next_month_on_current_config * COST_PER_UPTIME_CHECK_IN_DOLLARS
    end

    def expected_total_usage_next_month_on_proposed_config
      @expected_total_usage_next_month_on_proposed_config ||= (expected_total_usage_next_month_on_current_config + minutes_in_next_month).ceil
    end

    def expected_dollar_overage_next_month_on_proposed_config
      expected_total_usage_next_month_on_proposed_config * COST_PER_UPTIME_CHECK_IN_DOLLARS
    end

    def cost_of_proposed_changes
      expected_dollar_overage_next_month_on_proposed_config - expected_dollar_overage_next_month_on_current_config
    end

    private

    def uptime_checks_included_in_subscription_package
      @uptime_checks_included_in_subscription_package ||= @domain.subscription_feature_restriction.uptime_checks_included_per_month
    end

    def minutes_in_next_month
      (Time.current.next_month.end_of_month - Time.current.next_month.beginning_of_month) / 1.minute
    end
  end
end