class PerAutomatedTestRunSubscriptionPrice < SubscriptionPrice
  self.billable_model = TestRunWithTag
end