class PerAutomatedTestRunSubscriptionPriceOption < SubscriptionPriceOption
  self.billable_model = TestRunWithTag
end