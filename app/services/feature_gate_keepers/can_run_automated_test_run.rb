module FeatureGateKeepers
  class CanRunAutomatedTestRun < Base
    def can_access_feature?
      return true unless subscription_feature_restriction.automated_test_runs_included_per_month.present?
      num_automated_test_runs = domain.test_runs
                                        .joins(:audit)
                                        .merge(Audit.automated)
                                        .more_recent_than_or_equal_to(Time.current.beginning_of_month)
                                        .count
      if num_automated_test_runs >= subscription_feature_restriction.automated_test_runs_included_per_month
        @reason = <<~REASON
          Reached max number of automated test runs of #{num_automated_test_runs} while on the Starter Plan. Consider upgrading your plan.
        REASON
        false
      else
        true
      end
    end
  end
end