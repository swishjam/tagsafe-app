module OverageEstimators
  class ReleaseChecks
    COST_PER_RELEASE_CHECK_IN_DOLLARS = 0.002
    
    def initialize(domain:, tag:, new_release_check_interval:)
      @domain = domain
      @tag = tag
      @new_release_check_interval = new_release_check_interval.to_i
    end

    def price_would_increase?
      return false if @new_release_check_interval.zero?
      @new_release_check_interval < @tag.tag_preferences.release_check_minute_interval
    end

    def would_exceed_included_usage_for_subscription_package?
      return false if @new_release_check_interval.zero?
      expected_total_usage_next_month_on_proposed_config > release_checks_included_in_subscription_package
    end

    def expected_total_usage_next_month_on_current_config
      @expected_total_usage_next_month_on_current_config ||= begin
        num_release_checks_next_month = 0
        @domain.tags.release_monitoring_enabled.each do |tag|
          num_release_checks_next_month += minutes_in_next_month / tag.tag_preferences.release_check_minute_interval
        end
        num_release_checks_next_month.ceil
      end
    end

    def expected_dollar_overage_next_month_on_current_config
      (expected_total_usage_next_month_on_current_config - release_checks_included_in_subscription_package) * COST_PER_RELEASE_CHECK_IN_DOLLARS
    end

    def expected_total_usage_next_month_on_proposed_config
      @potential_additional_release_checks_next_month_on_new_interval ||= begin
        num_release_checks_next_month = expected_total_usage_next_month_on_current_config
        num_release_checks_next_month -= (minutes_in_next_month / @tag.tag_preferences.release_check_minute_interval).ceil
        num_release_checks_next_month += minutes_in_next_month / @new_release_check_interval
        num_release_checks_next_month.ceil
      end 
    end

    def expected_dollar_overage_next_month_on_proposed_config
      return 0 unless would_exceed_included_usage_for_subscription_package?
      (expected_total_usage_next_month_on_proposed_config - release_checks_included_in_subscription_package) * COST_PER_RELEASE_CHECK_IN_DOLLARS
    end

    def cost_of_proposed_changes
      return 0 unless would_exceed_included_usage_for_subscription_package?
      expected_dollar_overage_next_month_on_proposed_config - expected_dollar_overage_next_month_on_current_config
    end

    private

    def release_checks_included_in_subscription_package
      @release_checks_included_in_subscription_package ||= @domain.subscription_feature_restriction.release_checks_included_per_month
    end

    def minutes_in_next_month
      (Time.current.next_month.end_of_month - Time.current.next_month.beginning_of_month) / 1.minute
    end
  end
end