class PerUptimeCheckSubscriptionPriceOption < SubscriptionPriceOption
  self.billable_model = ReleaseCheck
end