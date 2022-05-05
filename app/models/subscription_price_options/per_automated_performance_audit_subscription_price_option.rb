class PerAutomatedPerformanceAuditSubscriptionPriceOption < SubscriptionPriceOption
  self.billable_model = AverageDeltaPerformanceAudit

  def self.for_subscription_package(subscription_package_type)
    where()
  end
end