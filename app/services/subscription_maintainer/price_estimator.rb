module SubscriptionMaintainer
  class PriceEstimator
    def initialize(tag_or_domain)
      @tag_or_domain = tag_or_domain
    end

    def estimate_monthly_price(in_cents: true)
      @tag_or_domain.is_a?(Tag) ? estimate_price_for_tag(@tag_or_domain) : estimate_price_for_domain
    end

    private

    def estimate_price_for_domain
      cost = 0
      @tag_or_domain.tags.each{ |tag| cost += estimate_price_for_tag(tag) }
      cost
    end

    def estimate_price_for_tag(tag)
      cost = 0
      cost += tag.scheduled_audits_enabled? && tag.tag_or_domain_configuration.include_performance_audit ? 
                1_440 / tag.tag_preferences.scheduled_audit_minute_interval * 30 * tag.domain.current_subscription_plan.per_automated_performance_audit_subscription_price.price_in_cents : 0
      cost += tag.scheduled_audits_enabled? && tag.tag_or_domain_configuration.include_functional_tests ? 
                1_440 / tag.tag_preferences.scheduled_audit_minute_interval * 30 * tag.domain.current_subscription_plan.per_automated_test_run_subscription_price.price_in_cents : 0
      cost += tag.release_monitoring_enabled? ? 1_440 / tag.tag_preferences.release_check_minute_interval * 30 * tag.domain.current_subscription_plan.per_release_check_subscription_price.price_in_cents * tag.uptime_regions.count : 0
      cost
    end
  end
end