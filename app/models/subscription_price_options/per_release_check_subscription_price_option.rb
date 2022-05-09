class PerReleaseCheckSubscriptionPriceOption < SubscriptionPriceOption
  self.billable_model = ReleaseCheck
end