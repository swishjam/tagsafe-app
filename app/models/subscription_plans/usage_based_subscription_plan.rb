class UsageBasedSubscriptionPlan < SubscriptionPlan
  has_one :current_domain, class_name: Domain.to_s, foreign_key: :current_usage_based_subscription_plan_id

  def per_automated_performance_audit_subscription_price
    subscription_prices.for(PerAutomatedPerformanceAuditSubscriptionPrice)
  end

  def per_automated_test_run_subscription_price
    subscription_prices.for(PerAutomatedTestRunSubscriptionPrice)
  end

  def per_tag_check_subscription_price
    subscription_prices.for(PerTagCheckSubscriptionPrice)
  end
end